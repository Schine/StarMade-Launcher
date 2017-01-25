'use strict'

os         = require('os')
fs         = require('fs')
path       = require('path')
shell      = require('shell')
spawn      = require('child_process').spawn
remote     = require('remote')

dialog     = remote.require('dialog')

util       = require('../util')
pkg        = require('../../package.json')
fileExists = require('../fileexists').fileExists


javaVersion      = pkg.javaVersion
javaJreDirectory = util.getJreDirectory javaVersion

app = angular.module 'launcher'

app.directive 'stringToNumber', ->
  {
    require: 'ngModel'
    link: (scope, element, attrs, ngModel) ->
      ngModel.$parsers.push (value) ->
        '' + value
      ngModel.$formatters.push (value) ->
        parseFloat value, 10
      return
  }


app.controller 'SettingsCtrl', ($scope, $rootScope, $timeout, $q, accessToken, settings) ->
  $scope.controller = "SettingsCtrl"
  # Store the dialog object for 2-way binding of dialog visibility
  $scope.dialog  = settings.dialog

  # Set up available panes
  $scope.availablePanes = ["launcher","memory","java"]  # install, build, about
  $scope.panes = {}
  for pane in $scope.availablePanes
    $scope.panes[pane] =
      name:           pane
      displayName:    "display name not set"
      icon:           "none"
      active:         false
      invalid:        false
      # Attributes to apply to markup as CSS classes
      classes:        ['active','invalid']
      # These bind `pane` within closures, and return anonymous functions that reference it.
      load:           ((pane) -> _pane = pane;  () -> new Promise (resolve,reject) -> ($rootScope.log.debug "Settings: #{_pane} pane's load function is not yet defined.";      resolve(); ))(pane)
      validate:       ((pane) -> _pane = pane;  () -> new Promise (resolve,reject) -> ($rootScope.log.debug "Settings: #{_pane} pane's validate function is not yet defined.";  resolve(); ))(pane)
      save:           ((pane) -> _pane = pane;  () -> new Promise (resolve,reject) -> ($rootScope.log.debug "Settings: #{_pane} pane's save function is not yet defined.";      resolve(); ))(pane)
      # Situationally useful events
      beforeShow:     () -> return;  # TODO: add `pane`.validate() here
      beforeHide:     () -> return;

      # Internal use; do not overwrite
      $classes:       ((pane) -> _pane = pane;  () -> (  # coffeescript requires `() -> (` to be on this line
          result  = []
          for attribute in $scope.panes[_pane].classes
            if $scope.panes[_pane][attribute]
              result.push attribute
          return result
        ))(pane)


  ### DEBUG ###
  $scope.$watch 'panes.java.active',     (newVal) -> $rootScope.log.important "Java pane: active?      #{newVal}"
  $scope.$watch 'panes.memory.active',   (newVal) -> $rootScope.log.important "Memory pane: active?    #{newVal}"
  $scope.$watch 'panes.launcher.active', (newVal) -> $rootScope.log.important "Launcher pane: active?  #{newVal}"
  ### END ###


  # Reload settings when showing the dialog
  $scope.$watch 'dialog.visible', (visible) ->
    return  unless settings.isReady()
    return  unless visible?

    # Workaround: `undefined` -> `false` should not trigger hide logic
    return  if not visible && not $scope.previousVisibility?
    $scope.previousVisibility = visible

    if visible
      return $scope.load()
    else
      for pane in $scope.availablePanes
        $scope.panes[pane].beforeHide()
      $rootScope.log.entry "Closed settings dialog"



  # Switch panes
  $scope.$watch 'dialog.pane', (pane) ->
    return  unless settings.isReady()
    return  unless pane?
    $rootScope.log.debug "(SettingsCtrl) New settings.dialog.pane: #{pane}"

    unless $scope.availablePanes.indexOf(pane)+1
      $rootScope.log.debug "settings.dialog.pane specifies an invalid settings pane (#{pane})"
      return
    # handle opening the pane
    $rootScope.log.debug "$scope.$watch dialog.pane: #{pane}; showing"
    $scope.show pane



  # Show a specific pane, hiding the rest
  $scope.show = (pane) ->
    $rootScope.log.debug "$scope.show(#{pane})"
    # Sanity check
    unless pane in $scope.availablePanes
      $rootScope.log.error "Attempting to show an invalid settings pane (#{pane})"
      return
    # Already visible
    if $scope.panes[pane].active
      return

    $rootScope.log.verbose "Presenting settings pane: #{pane}"
    $rootScope.log.indent()

    # Find the previous active pane(s)
    for each_pane in $scope.availablePanes
      continue  unless $scope.panes[each_pane].active
      # and call the pane's beforeHide() before hiding
      $scope.panes[each_pane].beforeHide()
      $scope.panes[each_pane].active = false

    # Prep pane for showing
    $scope.panes[pane].beforeShow()

    # Clear validation messages and invalid flag
    $scope.panes[pane].invalid = false
    $scope.validate.status     = ""
    $scope.validate.error      = ""

    # Validate pane and update its error message, styes, etc. when switching panes
    validation = $scope.panes[pane].validate()
    validation.then () ->
      $rootScope.log.important "#show() -> validate() -> then()"
      $scope.validate.status = "valid"
      if $scope.panes[pane].invalid
        $rootScope.log.important "#{pane} pane's validate failed"
        $scope.validate.status = "invalid"
        $scope.validate.error  = $scope.panes[pane].error || "(blank pane.error)"

      # Set the pane to active, and present the dialog
      $rootScope.log.important "Setting #{pane} pane to active"
      $scope.panes[pane].active = true
      $rootScope.log.debug "reread: $scope.panes.#{pane}.active: #{$scope.panes[pane].active}"
      settings.dialog.show()
      $rootScope.log.outdent()
      $scope.$apply()


    # This should never get called
    validation.catch (err) ->
      $rootScope.log.fatal "INTERNAL ERROR: panes.#{pane}.validate() rejected"
      $rootScope.log.outdent()
      return




  ### Per-pane functions ###

  initialSetup = new Promise (resolve, reject) ->
    $rootScope.log.verbose "Initializing settings backend"


    #
    #
    # --- Memory --------------------------------------------------------------
    #
    #

    $scope.panes.memory.displayName = "Game Memory"

    # ----- load ----- #

    # Load memory settings from storage, or set the defaults
    $scope.panes.memory.load = (do_initial_logging) ->
      new Promise (resolve, reject) ->
        if do_initial_logging
          $rootScope.log.entry "Memory settings"
          $rootScope.log.indent()

        totalRam = Math.floor( os.totalmem()/1024/1024 )  # bytes -> mb
        x64max   = 4096

        # Low system memory? decrease default max
        if totalRam <= 4096
          x64max = 2048
          if do_initial_logging
            $rootScope.log.info "Low system memory (#{totalRam}mb)"
            if os.arch() == "x64"
              $rootScope.log.indent.entry "Decreased default max memory from 4gb to 2gb"

        defaults = $scope.panes.memory.defaults =
          ia32:
            earlyGen:   64
            initial:   256
            max:       512      # initial memory.max value
            ceiling:  2048      # maximum value allowed
          x64:
            earlyGen:  128
            initial:   512
            max:      x64max    # initial memory.max value
            ceiling:  totalRam  # maximum value allowed
          step: 256             # Slider step



        # Cap max memory to physical ram
        _max = Number(localStorage.getItem('maxMemory')) || Number(defaults[os.arch()].max)
        $rootScope.log.indent.info "Max memory capped to physical ram"  if _max > defaults[os.arch()].ceiling && do_initial_logging
        _max = Math.min( _max, defaults[os.arch()].ceiling )


        $scope.panes.memory.max         = settings.memory.setMax      _max
        $scope.panes.memory.initial     = settings.memory.setInitial  Number(localStorage.getItem('initialMemory'))  || Number(defaults[os.arch()].initial)
        $scope.panes.memory.earlyGen    = settings.memory.setEarlyGen Number(localStorage.getItem('earlyGenMemory')) || Number(defaults[os.arch()].earlyGen)
        $scope.panes.memory.ceiling     =                             Number( defaults[os.arch()].ceiling )
        $scope.panes.memory.step        = 1   # Used by #maxMemoryInput.  See AngularJS workaround in beforeShow/Hide() above for why this isn't hardcoded.

        if do_initial_logging
          $rootScope.log.entry "max:       #{$scope.panes.memory.max}"
          $rootScope.log.entry "initial:   #{$scope.panes.memory.initial}"
          $rootScope.log.entry "earlyGen:  #{$scope.panes.memory.earlyGen}"
          $rootScope.log.entry "ceiling:   #{$scope.panes.memory.ceiling}"

        $scope.panes.memory.updateSlider()
        $rootScope.log.outdent()  if do_initial_logging
        resolve("$scope.panes.memory.load() resolved")


    # ----- save ----- #

    $scope.panes.memory.save = () ->
      new Promise (resolve, reject) ->
        messages = []

        if (localStorage.getItem('initialMemory') != "#{$scope.panes.memory.initial}")
          localStorage.setItem 'initialMemory', settings.memory.setInitial($scope.panes.memory.initial)
          messages.push "initial:  #{localStorage.getItem 'initialMemory'}"

        if (localStorage.getItem('earlyGenMemory') != "#{$scope.panes.memory.earlyGen}")
          localStorage.setItem 'earlyGenMemory', settings.memory.setEarlyGen($scope.panes.memory.earlyGen)
          messages.push "earlyGen: #{localStorage.getItem 'earlyGenMemory'}"

        if (localStorage.getItem('maxMemory') != "#{$scope.panes.memory.max}")
          localStorage.setItem 'maxMemory', settings.memory.setMax($scope.panes.memory.max)
          messages.push "max:      #{localStorage.getItem 'maxMemory'}"


        if messages.length
          $rootScope.log.event "Saving memory settings"
          $rootScope.log.indent.entry message  for message in messages

        resolve("$scope.panes.memory.save() resolved")



    # ---- events ---- #

    # AngularJS workaround: specifying non-multiples of `step` throws an error upon hiding the control.  hacky workaround.
    $scope.panes.memory.beforeHide = () ->
      $rootScope.log.important "memory.beforeHide()"
      $scope.panes.memory.step = 1
    $scope.panes.memory.beforeShow = () ->
      $rootScope.log.important "memory.beforeShow()"
      $scope.panes.memory.step = $scope.panes.memory.defaults.step
      $scope.panes.memory.updateSlider()



    # ---(internal)--- #

    $scope.$watch 'panes.memory.earlyGen', (newVal) ->
      return  unless document.getElementById("maxMemorySlider")?  # Ensure markup has loaded  #TODO: perhaps settings.isReady() ?
      return  if     typeof $scope.panes.memory == "undefined"
      $scope.panes.memory.updateSlider(newVal, $scope.panes.memory.initial)

    $scope.$watch 'panes.memory.initial', (newVal) ->
      return  unless document.getElementById("maxMemorySlider")?  # Ensure markup has loaded  #TODO: perhaps settings.isReady() ?
      return  if     typeof $scope.panes.memory == "undefined"
      $scope.panes.memory.updateSlider($scope.panes.memory.earlyGen, newVal)


    # Update slider when `panes.memory.max` changes via textbox
    $scope.panes.memory.set_memory_slider_value = (newVal) ->
      #TODO: could do this within the view
      $scope.panes.memory.slider = newVal
      #TODO: and then replace this with `$scope.$watch 'panes.memory.slider', () ->`
      $scope.panes.memory.update_slider_class()


    # Called by slider updates
    $scope.panes.memory.snapSlider = (newVal) ->
      _nearest_pow_2 = nearestPow2(newVal)
      _floor         = $scope.panes.memory.floor

      # Snap to lower bound if between `floor` and `(floor + floor->pow2)/2`
      if newVal <= (_floor + nearestPow2(_floor, false)) >> 1  # false: bypass nearestPow2() memoizing
        $scope.panes.memory.max = _floor
      else
        # Snap to nearest pow2 (higher than the lower bound, capped at memory ceiling)
        $scope.panes.memory.max = Math.max(_floor, Math.min(_nearest_pow_2, $scope.panes.memory.ceiling))


      # Allow snapping up to end of slider, power of 2 or not
      if $scope.panes.memory.max != $scope.panes.memory.ceiling
        if newVal >= ($scope.panes.memory.max + $scope.panes.memory.ceiling) / 2
          $scope.panes.memory.max = $scope.panes.memory.ceiling


      $scope.panes.memory.slider = $scope.panes.memory.max
      $scope.panes.memory.update_slider_class()
      $rootScope.log.verbose "Slider: Snapping from #{newVal} to #{$scope.panes.memory.max}"

      # Log bounding errors  (these should never happen)
      if $scope.panes.memory.max > $scope.panes.memory.ceiling
        $rootScope.log.error "Snapped above memory ceiling (#{$scope.panes.memory.max} > #{$scope.panes.memory.ceiling})"
      if $scope.panes.memory.max < $scope.panes.memory.floor
        $rootScope.log.error "Snapped below memory floor (#{$scope.panes.memory.max} < #{$scope.panes.memory.floor})"


    $scope.panes.memory.update_slider_class = () ->
      return if not settings.isReady()  # Race condition, as this is indirectly called during settings loading
      # ensure there's only one bit set:
      # (nonzero, no bits match val-1)
      val  = $scope.panes.memory.slider
      pow2 = val && !(val & (val-1))

      # Set flag and update class
      $scope.panes.memory.power_of_2 = pow2
      document.getElementById("maxMemorySlider").classList.add("power-of-2")     if  pow2
      document.getElementById("maxMemorySlider").classList.remove("power-of-2")  if !pow2



    # ensure Max >= initial+earlyGen; update slider's value
    $scope.panes.memory.updateSlider = (earlyGen, initial) ->
      # If the user cleared the max memory value, don't update the slider (as it will reset to initial+early)
      return  if $scope.panes.memory.max == null

      earlyGen = $scope.panes.memory.earlyGen  if typeof earlyGen == "undefined"
      initial  = $scope.panes.memory.initial   if typeof initial  == "undefined"

      # Still invalid?  bypass updating until they're set.
      return  if typeof earlyGen == "undefined"
      return  if typeof initial  == "undefined"

      _do_logging = true if not $rootScope.alreadyExecuted("Log - updateSlider", 1000)

      if _do_logging?
        $rootScope.log.verbose "Updating memory slider"
        $rootScope.log.indent.entry "earlyGen: #{earlyGen}", $rootScope.log.levels.verbose
        $rootScope.log.indent.entry "initial:  #{initial}",  $rootScope.log.levels.verbose
        $rootScope.log.indent()

      $scope.panes.memory.updateFloor()  # update floor whenever initial/earlyGen change


      $scope.panes.memory.max    = Math.max($scope.panes.memory.floor, $scope.panes.memory.max)
      $scope.panes.memory.slider = $scope.panes.memory.max
      $scope.panes.memory.update_slider_class() # toggles green and labels when at a power of 2

      if _do_logging?
        $rootScope.log.outdent()
        $rootScope.log.indent.entry "max:      #{$scope.panes.memory.max}",    $rootScope.log.levels.verbose
        $rootScope.log.indent.entry "slider:   #{$scope.panes.memory.slider}", $rootScope.log.levels.verbose


      # Workaround for Angular's range bug  (https://github.com/angular/angular.js/issues/6726)
      $timeout ->
        ele = document.getElementById("maxMemorySlider")
        ele.value = $scope.panes.memory.max  if ele?


    # max memory should be >= early+initial
    $scope.panes.memory.updateFloor = () ->
      # deleting the contents of the `earlyGen` and/or `initial` textboxes causes problems.  setting a min value here fixes it.
      $scope.panes.memory.floor = Math.max($scope.panes.memory.earlyGen + $scope.panes.memory.initial, 256)  # 256 minimum
      if not $rootScope.alreadyExecuted("Log - $scope.panes.memory.updateFloor", 1000)
        $rootScope.log.verbose "Updating memory floor"
        $rootScope.log.indent.entry "setting memory.floor to #{$scope.panes.memory.floor}", $rootScope.log.levels.verbose




    # --- Validate --- #

    $scope.panes.memory.validate = ->
      new Promise (resolve, reject) ->
        $rootScope.log.debug "panes.memory.validate()"
        $rootScope.log.indent(1, $rootScope.log.levels.debug)

        # Validate memory settings
        validations = []
        validations.push $scope.panes.memory.validate.max()
        validations.push $scope.panes.memory.validate.initial()
        validations.push $scope.panes.memory.validate.earlyGen()

        validation = $q.all(validations)

        # Validation passed
        validation.then () =>
          $scope.validate.clear('memory')
          $rootScope.log.outdent(1, $rootScope.log.levels.debug)
          resolve()

        # Validation failed
        validation.catch (reason) =>
          $rootScope.log.debug "panes.memory.validate: REJECT! (#{reason})"
          $scope.validate.fail('memory', reason)
          $rootScope.log.outdent(1, $rootScope.log.levels.debug)
          resolve()

        #TODO: on fail, show pane, highlight control, reject()
        # reject("invalid initial memory")         unless $scope.panes.memory.validate.initial()
        # reject("invalid earlyGen memory")        unless $scope.panes.memory.validate.earlyGen()
        # reject("invalid max memory")             unless $scope.panes.memory.validate.max()
        # reject("earlyGen > initial memory")      if     $scope.panes.memory.earlyGen >= $scope.panes.memory.initial
        # reject("max memory < initial+earlyGen")  if     $scope.panes.memory.max      <  $scope.panes.memory.initial + $scope.panes.memory.earlyGen
        # reject("max memory exceeds ceiling")     if     $scope.panes.memory.max      >  $scope.panes.memory.ceiling

    # Stub called by view to supress errors
    $scope.panes.memory.validate.stub = ->
      validation = $scope.panes.memory.validate()
      validation.catch (err) -> return
      return

    $scope.panes.memory.validate.max = ->
      return  unless settings.isReady()
      new Promise (resolve, reject) ->
        $rootScope.log.debug "panes.memory.validate.max()"
        $rootScope.log.indent.debug "value:  #{$scope.panes.memory.max}"
        $rootScope.log.indent.debug "typeof: #{typeof $scope.panes.memory.max}"

        # Set to false until validation passes
        $scope.panes.memory.validate.max.valid = false
        err = null

        type  = typeof $scope.panes.memory.max
        max   = $scope.panes.memory.max
        floor = ($scope.panes.memory.initial + $scope.panes.memory.earlyGen)

        # Invalid data
        err or= "memory.max: invalid value specified"        if     $scope.panes.memory.max == undefined
        err or= "memory.max is blank"                        if     $scope.panes.memory.max == null
        err or= "memory.max is not a number (type #{type})"  unless type == "number"
        # Floor and ceiling bounds
        err or= "memory.max: max > total system RAM"         if     max > $scope.panes.memory.ceiling
        err or= "memory.max: max < (initial + earlyGen)"     if     max < floor

        reject(err)  if err?

        # Valid!
        $scope.panes.memory.validate.max.valid = true
        resolve()


    $scope.panes.memory.validate.initial = ->
      new Promise (resolve, reject) ->
        $rootScope.log.debug "panes.memory.validate.initial()"
        $scope.panes.memory.validate.initial.valid = false
        err = null

        # Invalid data
        err or= "memory.initial: invalid value specified"      if $scope.panes.memory.initial == undefined
        err or= "memory.initial is blank"                      if $scope.panes.memory.initial == null
        err or= "memory.initial must be larger than earlyGen"  if $scope.panes.memory.earlyGen >= $scope.panes.memory.initial

        reject(err)  if err?

        # Valid!
        $scope.panes.memory.validate.initial.valid = true
        resolve()


    $scope.panes.memory.validate.earlyGen = ->
      new Promise (resolve, reject) ->
        $rootScope.log.debug "panes.memory.validate.earlyGen()"
        $scope.panes.memory.validate.earlyGen.valid = false
        err = null

        # Invalid data
        err or= "memory.earlyGen: invalid value specified"  if $scope.panes.memory.earlyGen == undefined
        err or= "memory.earlyGen is blank"                  if $scope.panes.memory.earlyGen == null

        reject(err)  if err?

        # Valid!
        $scope.panes.memory.validate.earlyGen.valid = true
        resolve()


    $scope.panes.memory.validate.max.class      = ->
      return "invalid"  unless $scope.panes.memory.validate.max.valid
      return "critical" if     $scope.panes.memory.max < 2048
      return "warning"  if     $scope.panes.memory.max < 4096
    $scope.panes.memory.validate.initial.class  = ->
      return "invalid"  unless $scope.panes.memory.validate.initial.valid
      return "invalid"  if     $scope.panes.memory.initial <= $scope.panes.memory.earlyGen
      return "warning"  if     $scope.panes.memory.initial <  256
    $scope.panes.memory.validate.earlyGen.class = ->
      return "invalid"  unless $scope.panes.memory.validate.earlyGen.valid


    #
    #
    # --- Launcher ------------------------------------------------------------
    #
    #

    $scope.panes.launcher.displayName = "Launcher"

    # ----- load ----- #
    $scope.panes.launcher.load     = () -> new Promise (resolve, reject) ->  resolve("$scope.panes.launcher.load() resolved")      # No loading    required
    # --- validate --- #
    $scope.panes.launcher.validate = () -> new Promise (resolve, reject) ->  resolve("$scope.panes.launcher.validate() resolved")  # No validation required
    # ----- save ----- #
    $scope.panes.launcher.save     = () -> new Promise (resolve, reject) ->  resolve("$scope.panes.launcher.save() resolved")      # No saving     required


    #
    #
    # --- Java ----------------------------------------------------------------
    #
    #

    $scope.panes.java.displayName = "Java"

    # ----- load ----- #

    $scope.panes.java.load = (do_initial_logging) ->
      new Promise (resolve, reject) ->
        $rootScope.log.entry "Java settings"  if do_initial_logging
        $rootScope.log.indent()

        $scope.panes.java.path = settings.java.setPath(localStorage.getItem('javaPath'))
        $scope.panes.java.args = settings.java.setArgs(localStorage.getItem('javaArgs'))

        # Set default args when not set
        $scope.panes.java.resetArgs()  if not $scope.panes.java.args?

        if do_initial_logging
          $rootScope.log.entry "Java:     Bundled"                unless settings.java.path
          $rootScope.log.entry "Java:     Custom Install"         if     settings.java.path
          $rootScope.log.entry "Path:     #{settings.java.path}"  if     settings.java.path
          $rootScope.log.entry "Args:     #{settings.java.args}"

        $rootScope.log.outdent()
        resolve("$scope.panes.java.load() resolved")



    # ----- save ----- #

    $scope.panes.java.save = () ->
      new Promise (resolve, reject) ->
        messages = []

        if settings.java.args != $scope.panes.java.args
          localStorage.setItem('javaArgs', settings.java.setArgs($scope.panes.java.args))
          messages.push "args: #{settings.java.args}"

        if settings.java.path != $scope.panes.java.path
          localStorage.setItem('javaPath', settings.java.setPath($scope.panes.java.path))
          if not settings.java.path
            messages.push "Java:     Bundled"
          else
            messages.push "Java:     Custom Install"
            messages.push "Path:     #{settings.java.path}"


        if messages.length
          $rootScope.log.event "Saving Java settings"
          $rootScope.log.indent.entry message  for message in messages

        resolve("$scope.panes.java.save() resolved")


    $scope.panes.java.resetArgs = () ->
      _args = []
      _args.push('-Xincgc')
      _args.push('-server')  if (os.arch() == "x64")
      _args = _args.join(" ")
      # Don't bother if they've already been reset
      return  if $scope.panes.java.args == _args

      $scope.panes.java.args = _args
      $rootScope.log.info "Reset java args to defaults"
      $rootScope.log.indent.entry _args


    $scope.panes.java.browse = () =>
      $rootScope.log.event("Browsing for custom Java path", $rootScope.log.levels.verbose)
      dialog.showOpenDialog remote.getCurrentWindow(),
        title: 'Select Java Bin Directory'
        properties: ['openDirectory']
        defaultPath: $scope.panes.java.path
      , (newPath) =>
        if not newPath?
          $rootScope.log.indent.verbose "Canceled"
          return
        $rootScope.log.indent.verbose "New path: #{newPath[0]}"
        $scope.panes.java.path = newPath[0]
        $scope.panes.java.validate.stub()
        $scope.$apply()



    # --- validate --- #

    $scope.panes.java.validate = () ->
      new Promise (resolve, reject) ->
        $rootScope.log.debug "panes.java.validate()"
        $rootScope.log.indent(1, $rootScope.log.levels.debug)
        if $scope.panes.java.validate.path()
          $scope.validate.clear('java')
          $rootScope.log.outdent(1, $rootScope.log.levels.debug)
          return resolve()

        reason = "Invalid custom Java path"
        $rootScope.log.debug "panes.java.validate()  REJECT: #{reason}"
        $scope.validate.fail('java', reason)
        $rootScope.log.outdent(1, $rootScope.log.levels.debug)
        resolve()


    # Stub called by view to supress errors
    $scope.panes.java.validate.stub = ->
      validation = $scope.panes.java.validate()
      validation.catch (err) -> return
      return


    $scope.panes.java.validate.path = () ->
      newPath = $scope.panes.java.path

      # Blank path: use bundled java
      if newPath.length == 0
        $scope.panes.java.validate.pathStatus = "bundled"
        $rootScope.log.debug "panes.java.validate.path(): bundled"
        return true

      # Custom path: verify
      newPath = path.resolve(newPath)
      if fileExists( path.join(newPath, "java") )  ||  # osx+linux
         fileExists( path.join(newPath, "java.exe") )  # windows
         # Valid
        $rootScope.log.debug "panes.java.validate.path(): custom"
        $scope.panes.java.validate.pathStatus = "custom"
        return true

      # Invalid path
      $scope.panes.java.validate.pathStatus = "invalid"
      $rootScope.log.debug "panes.java.validate.path(): invalid"
      return false


    $scope.panes.java.validate.path.class = () ->
      # Applies to `java.path` input
      return "status"  unless $scope.panes.java.validate.pathStatus == "invalid"
      return "error"


    # ---- Events ---- #

    $scope.panes.java.beforeShow = () ->
      $rootScope.log.important "java.beforeShow()"
      $scope.panes.java.validate.path("bypass_logging")



    #
    #
    # -------------------------------------------------------------------------
    #
    #


    $rootScope.log.verbose "Settings backend initialized"
    resolve()
    ### End per-pane functions ###





  ### Load all panes ###


  # Load all settings panes' data
  $scope.load = (do_initial_logging) ->
    new Promise (resolve, reject) ->
      do_initial_logging = !!do_initial_logging  # allow strings for readibility

      $rootScope.log.event "Loading settings panes" + if do_initial_logging then " (initial)" else ""
      $rootScope.log.indent()


      # Load each pane in sequence
      result = Promise.resolve()
      $scope.availablePanes.forEach (pane) ->
        result = result.then () ->
          $scope.panes[pane].load(do_initial_logging).then () ->
            # and validate
            $scope.panes[pane].validate()

      result.catch (err) ->
        $rootScope.log.error "Loading failed"
        $rootScope.log.indent.entry (err || err.message || "(unknown error)")
        $rootScope.log.outdent()
        reject()

      result.then () ->
        $rootScope.log.outdent()
        resolve()




  ### Validate all panes ###


  # Validate all settings panes' data
  $scope.validate = () ->
    new Promise (resolve, reject) ->
      $rootScope.log.event "Validating settings"
      $rootScope.log.indent()
      $scope.validate.status = "validating"

      # Iterate through all panes and push their validation onto promise array
      validations = []
      for pane in $scope.availablePanes  # ["java","memory","launcher"]
        $rootScope.log.debug "validating pane: #{pane}"
        $rootScope.log.indent()
        validations.push $scope.panes[pane].validate()
        $rootScope.log.outdent()


      # Wait for all promises to resolve
      # TODO: make this serial
      validation = $q.all(validations)
      validation.then () =>
        # Loop through the panes
        for pane in $scope.availablePanes
          continue  unless $scope.panes[pane].invalid
          $scope.show(pane)
          $rootScope.log.outdent()
          return reject("#{pane} validation failed")  # and prevent saving

        # otherwise resolve
        $scope.validate.status = "valid"
        $rootScope.log.debug "Validation passed"
        $rootScope.log.outdent()
        resolve()

      # Log failure otherwise
      validation.catch (err) ->
        msg = (err || err.message || null)
        $rootScope.log.fatal "Internal error: pane validation rejected."
        $rootScope.log.indent.entry msg  if msg
        $rootScope.log.outdent()
        reject("internal error")



  # --- Clear invalid flag ---

  $scope.validate.clear = (pane) ->
    $rootScope.log.debug "validate.clear(#{pane})"
    $scope.panes[pane].invalid = false
    $scope.panes[pane].error   = null
    # Clear current message if the pane is active.
    if $scope.panes[pane].active
      $scope.validate.status = "valid"
      $scope.validate.error  = null


  # --- Validation failure ---

  $scope.validate.fail = (pane, error) ->
    $rootScope.log.debug "validate.fail(#{pane}, #{error})"
    $scope.validate.status     = "invalid"
    $scope.panes[pane].error   = error || "Validation failed"
    $scope.panes[pane].invalid = true


    $rootScope.log.indent.debug "current (#{pane}) pane active?  #{$scope.panes[pane].active}"

    # Show the validation error if it's for the current pane
    if $scope.panes[pane].active
      $scope.validate.error  = $scope.panes[pane].error || "(blank pane.error)"




  ### Save all panes ###


  # Save all settings panes' data
  $scope.save = () ->
    $rootScope.log.verbose "User clicked [save]"

    $scope.validate().then () ->
      $rootScope.log.event "Saving settings"
      $rootScope.log.indent()

      saves = []

      save_serial = new Promise (resolve, reject) ->
        result = Promise.resolve()
        $scope.availablePanes.forEach (pane) =>
          result = result.then () =>
            $rootScope.log.verbose "Saving pane: #{pane}"
            $rootScope.log.indent()
            _save = $scope.panes[pane].save()
            saves.push _save
            $rootScope.log.outdent()
            return _save

        result.then () ->
          resolve()


      save_serial.then () ->
        saving = $q.all(saves)
        saving.then () ->
          $rootScope.log.entry "Complete"
          $rootScope.log.outdent()
          settings.dialog.hide()

        saving.catch (err) ->
          $rootScope.log.error "Saving failed"
          $rootScope.log.indent.error "#{err.message || err || '(unknown error)'}"
          $rootScope.log.outdent()

    .catch (err) ->
      $rootScope.log.debug "Pre-save validation failed (#{err.message || err || '(unknown error)'})"
      return






  #
  #
  # -------------------------------------------------------------------------
  #
  #


  ### Post initial setup ###

  # Load settings immediately after initial setup
  initialSetup.then () ->
    $scope.load("initial").then () ->
      # Set the first pane as active, and call its beforeShow method
      $scope.panes[$scope.availablePanes[0]].active = true
      $scope.panes[$scope.availablePanes[0]].beforeShow()
      $scope.panes[$scope.availablePanes[0]].validate()
      # And mark settings as ready
      settings.setReady()  ##TODO: Should I call this after saving as well?


  # Catch errors during initial setup
  # These are (basically) unrecoverable as settings.setReady() would never happen
  initialSetup.catch (err) ->
    $rootScope.log.fatal "Failed to load settings"
    $rootScope.log.indent.entry (err || err.message || "(unknown error)")
    remote.require('app').quit()





  #
  #
  # -------------------------------------------------------------------------
  #
  #


  ### Local functions ###

  # TODO: Move these into their pane's scope

  $scope.showChangelog = ->
    $rootScope.log.debug "showChangelog()"
    localStorage.removeItem "presented-changelog"
    ipc.send "open-changelog"

  $scope.openDownloadPage = ->
    $rootScope.log.event "Opening download page: https://star-made.org/download"
    shell.openExternal 'https://star-made.org/download'

  $scope.openSteamLink = ->
    $rootScope.log.event "opening: https://registry.star-made.org/profile/steam_link"
    shell.openExternal 'https://registry.star-made.org/profile/steam_link'


  nearestPow2_clear_bounds = () ->
    # Leaving the stored bounds intact does not cause incorrect results.
    # clearing them, however, slightly speeds up any subsequent calls with too-far-out-of-bounds values (>=1 power in either direction)
    #   ex: nearestPow2(255)  then  nearestPow2(1023)
    pow2_lower_bound = null
    pow2_upper_bound = null

  # As this is kind of hard to read, I've added comments describing the bitwise math I've used.
  # Works for up values up to 30 bits (javascript limitation)
  # Undefined behavior for values < 1
  nearestPow2 = (val, memoize=true) ->
    # Memoize to speed up subsequent calls with similar values
    if memoize && typeof pow2_lower_bound == "number"  &&  typeof pow2_upper_bound == "number"  # Skip entire block if bounds are undefined/incorrect
      # no change?
      return pow2_current_power  if val == pow2_current_power

      # Prev/Next powers are guaranteed powers of 2, so simply return them.
      if val == pow2_next_power
        nearestPow2_clear_bounds() # Clear bounds to speed up the next call
        return pow2_next_power
      if val == pow2_prev_power
        nearestPow2_clear_bounds()
        return pow2_prev_power

      # Halfway bounds allow quick rounding:
      #  - Within bounds
      if (val > pow2_current_power  &&  val < pow2_upper_bound)  ||  (val < pow2_current_power  && val >= pow2_lower_bound)
        return pow2_current_power

      #  - Between upper bound and next power
      if (val >= pow2_upper_bound && val <= pow2_next_power)
        nearestPow2_clear_bounds()
        return pow2_next_power

      #  - Between lower bound and previous power
      if (val <  pow2_lower_bound && val >= pow2_prev_power)
        nearestPow2_clear_bounds()
        return pow2_prev_power


    # Already a power of 2? simply return it.
    # (As this scenario is rare, checking likely lowers performance)
    return val  if (val & (val-1)) == 0  # This will be nonzero (and therefore fail) if there are multiple bits set.


    # Round to nearest power of 2 using bitwise math:
    val         = ~~val  # Fast floor via double bitwise not
    val_copy    = val
    shift_count = 0
    # Count the number of bits to the right of the most-significant bit:  111011 -> 5
    while val_copy > 1
      val_copy = val_copy >>> 1   # >>> left-fills with zeros
      shift_count++

    # If the value's second-most-significant bit is set (meaning it's halfway to the next power), add a shift to round up
    if val & (1 << (shift_count - 1))
      shift_count++

    # Construct the power by left-shifting  --  much faster than Math.pow(2, shift_count)
    val = 1 << shift_count

    # Shortcut if not memoizing
    return val if not memoize

    # ... and memoize by storing halfway bounds and the next/prev powers
    pow2_next_power    = val <<  1
    pow2_upper_bound   = val + (val >>> 1)          # Halfway up   (x*1.5)
    pow2_current_power = val
    pow2_lower_bound   = (val >>> 1) + (val >>> 2)  # Halfway down (x/2 + x/4)
    pow2_prev_power    = val >>> 1

    # Return our shiny new power of 2 (:
    return val


  ###
  # todo:                      css on buttons
  #                            remove or fix drop shadow (height)
  #                            look into memory validation log ordering
  #                            clean up overall logging
  #                            add the other two panes (gears)
  #                            test settings.showPane() function
  # $scope.validation:         serial promises.
  #                           *loop through panes; show first invalid, update message, and reject.  resolve otherwise
  # $scope.panes[].validate:  *run all validations
  #                           *then:  clear invalid flag+message, resolve
  #                           *catch: set   invalid flag+message, resolve.
  #                            show validation error if the pane is active
###