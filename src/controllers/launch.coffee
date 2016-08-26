'use strict'

os         = require('os')
fs         = require('fs')
path       = require('path')
spawn      = require('child_process').spawn
remote     = require('remote')

dialog     = remote.require('dialog')

util       = require('../util')
fileExists = require('../fileexists').fileExists
pkg        = require('../../package.json')

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


app.controller 'LaunchCtrl', ($scope, $rootScope, $timeout, accessToken) ->
  totalRam = Math.floor( os.totalmem()/1024/1024 )  # bytes -> mb
  x64max   = 4096

  # Low system memory? decrease default max
  if totalRam <= 4096
    x64max = 2048
    if not $rootScope.alreadyExecuted 'log low system memory'
      $rootScope.log.info "Low system memory (#{totalRam}mb)"
      $rootScope.log.indent()
      $rootScope.log.entry   "Decreased default max memory from 4gb to 2gb"
      $rootScope.log.outdent()

  defaults =
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


  $scope.launcherOptions = {}

  # restore previous settings, or use the defaults
  $scope.serverPort               = localStorage.getItem('serverPort') || 4242
  $scope.launcherOptions.javaPath = localStorage.getItem('javaPath')   || ""



  ### _JAVA_OPTIONS Dialog ###

  $scope.showEnvJavaOptionsWarning = () ->
    $scope._java_options.show_dialog = true
    return if $rootScope.alreadyExecuted 'log _JAVA_OPTIONS Dialog'

    $rootScope.log.info "_JAVA_OPTIONS=#{process.env['_JAVA_OPTIONS']}"
    $rootScope.log.event "Presenting _JAVA_OPTIONS Dialog"

  $scope.get_java_options = () ->
    (process.env["_JAVA_OPTIONS"] || '').trim()

  $scope.clearEnvJavaOptions = () ->
    process.env["_JAVA_OPTIONS"] = ''
    $rootScope.log.info "Cleared _JAVA_OPTIONS"
    $scope._java_options.show_dialog = false

  $scope.saveEnvJavaOptionsWarning = () ->
    process.env["_JAVA_OPTIONS"] = $scope._java_options.modified

    if process.env["_JAVA_OPTIONS"] == ''
      $rootScope.log.info "Cleared _JAVA_OPTIONS"
    else
      $rootScope.log.info "Set _JAVA_OPTIONS to: #{process.env['_JAVA_OPTIONS']}"
    $scope._java_options.show_dialog = false

  $scope.closeEnvJavaOptionsWarning = () ->
    $rootScope.log.entry "Keeping _JAVA_OPTIONS intact"
    $scope._java_options.show_dialog = false


  # Must follow function declarations
  if process.env["_JAVA_OPTIONS"]?
    $scope._java_options = {}
    $scope._java_options.modified    = $scope.get_java_options()
    $scope._java_options.show_dialog = false
    $scope.showEnvJavaOptionsWarning()




  $scope.$watch 'serverPort', (newVal) ->
    localStorage.setItem 'serverPort', newVal

  $scope.$watch 'memory.earlyGen', (newVal) ->
    return  if (typeof $scope.memory == "undefined")
    updateMemorySlider(newVal, $scope.memory.initial)
  $scope.$watch 'memory.initial', (newVal) ->
    return  if (typeof $scope.memory == "undefined")
    updateMemorySlider($scope.memory.earlyGen, newVal)


  # Update slider when memory.max changes via textbox
  $scope.set_memory_slider_value = (newVal) ->
    $scope.memory.slider = newVal
    update_slider_class()

  # Called by slider updates
  $scope.snap_memory = (newVal) ->
    _nearest_pow_2 = nearestPow2(newVal)
    _floor         = $scope.memory.floor

    # Snap to lower bound if between `floor` and `(floor + floor->pow2)/2`
    if newVal <= (_floor + nearestPow2(_floor, false)) >> 1  # false: bypass nearestPow2() memoizing
      $scope.memory.max = _floor
    else
      # Snap to nearest pow2 (capped at memory ceiling)
      $scope.memory.max = Math.min(_nearest_pow_2, $scope.memory.ceiling)
  
    # Allow snapping up to end of slider, power of 2 or not
    if $scope.memory.max != $scope.memory.ceiling
      if newVal >= ($scope.memory.max + $scope.memory.ceiling) / 2
        $scope.memory.max = $scope.memory.ceiling


    $scope.memory.slider = $scope.memory.max
    update_slider_class()
    $rootScope.log.verbose "Slider: Snapping from #{newVal} to #{$scope.memory.max}"


  update_slider_class = () ->
    # ensure there's only one bit set:
    # (nonzero, no bits match val-1)
    val  = $scope.memory.slider
    pow2 = val && !(val & (val-1))

    # Set flag and update class
    $scope.memory.power_of_2 = pow2
    document.getElementById("maxMemorySlider").classList.add("power-of-2")     if  pow2
    document.getElementById("maxMemorySlider").classList.remove("power-of-2")  if !pow2


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



  # ensure Max >= initial+earlyGen; update slider's value
  updateMemorySlider = (earlyGen, initial) ->
    earlyGen = $scope.memory.earlyGen  if typeof earlyGen == "undefined"
    initial  = $scope.memory.initial   if typeof initial  == "undefined"

    # Still invalid?  bypass updating until they're set.
    return  if typeof earlyGen == "undefined"
    return  if typeof initial  == "undefined"

    $rootScope.log.event("updateMemorySlider():", $rootScope.log.levels.verbose)
    $rootScope.log.indent()
    $rootScope.log.verbose "earlyGen: #{earlyGen}     "
    $rootScope.log.verbose "initial:  #{initial}      "

    updateMemoryFloor()  # update floor whenever initial/earlyGen change


    $scope.memory.max    = Math.max($scope.memory.floor, $scope.memory.max)
    $scope.memory.slider = $scope.memory.max
    update_slider_class() # toggles green and labels when at a power of 2

    $rootScope.log.verbose "max:      #{$scope.memory.max}"
    $rootScope.log.verbose "slider:   #{$scope.memory.slider}"
    $rootScope.log.outdent()

    # Workaround for Angular's range bug  (https://github.com/angular/angular.js/issues/6726)
    $timeout ->
      document.getElementById("maxMemorySlider").value = $scope.memory.max


  # max memory should be >= early+initial
  updateMemoryFloor = () ->
    # deleting the contents of the `earlyGen` and/or `initial` textboxes causes problems.  setting a min value here fixes it.
    $scope.memory.floor = Math.max($scope.memory.earlyGen + $scope.memory.initial, 256)  # 256 minimum
    $rootScope.log.event("updateMemoryFloor():", $rootScope.log.levels.verbose)
    $rootScope.log.indent()
    $rootScope.log.verbose "setting memory.floor to #{$scope.memory.floor}"
    $rootScope.log.outdent()


  # Load memory settings from storage or set the defaults
  loadMemorySettings = ->
    $rootScope.log.event "Loading memory settings"
    $rootScope.log.indent()

    # Cap max memory to physical ram
    _max = Number(localStorage.getItem('maxMemory')) || Number(defaults[os.arch()].max)
    $rootScope.log.info "Max memory capped to physical ram"  if _max > defaults[os.arch()].ceiling
    _max = Math.min( _max, defaults[os.arch()].ceiling )

    $scope.memory =
      max:      _max
      initial:  Number(localStorage.getItem('initialMemory'))  || Number(defaults[os.arch()].initial)
      earlyGen: Number(localStorage.getItem('earlyGenMemory')) || Number(defaults[os.arch()].earlyGen)
      ceiling:  Number( defaults[os.arch()].ceiling )
      step:     256  # Used by #maxMemoryInput.  See AngularJS workaround in $scope.closeClientOptions() below for why this isn't hardcoded.

    $rootScope.log.entry "maxMemory:      #{$scope.memory.max}"
    $rootScope.log.entry "initialMemory:  #{$scope.memory.initial}"
    $rootScope.log.entry "earlyGenMemory: #{$scope.memory.earlyGen}"
    $rootScope.log.entry "ceiling:        #{$scope.memory.ceiling}"
    $rootScope.log.outdent()

    updateMemorySlider()


  $scope.openClientMemoryOptions = ->
    loadMemorySettings()
    $scope.clientMemoryOptions = true

  $scope.closeClientOptions = ->
    $scope.memory.step = 1    # AngularJS workaround: specifying non-multiples of {{step}} throws an error upon hiding the control.  hacky workaround.
    $scope.clientMemoryOptions = false


  $scope.saveClientOptions = ->
    localStorage.setItem 'maxMemory',      $scope.memory.max
    localStorage.setItem 'initialMemory',  $scope.memory.initial
    localStorage.setItem 'earlyGenMemory', $scope.memory.earlyGen

    $rootScope.log.event "Saving memory settings"
    $rootScope.log.indent()
    $rootScope.log.entry "maxMemory:      #{$scope.memory.max}"
    $rootScope.log.entry "initialMemory:  #{$scope.memory.initial}"
    $rootScope.log.entry "earlyGenMemory: #{$scope.memory.earlyGen}"
    $rootScope.log.outdent()

    $scope.closeClientOptions()


  $scope.steamLaunch = ->
    return $rootScope.steamLaunch

  $scope.buildVersion = ->
    return $rootScope.buildVersion


  $scope.$watch 'launcherOptions.javaPath', (newVal) ->
    localStorage.setItem 'javaPath', newVal
    $rootScope.javaPath = newVal


  $scope.$watch 'launcherOptionsWindow', (visible) ->
    return  if not visible
    $scope.verifyJavaPath()

  $scope.launcherOptions.javaPathBrowse = () =>
    $rootScope.log.event("Browsing for custom java path", $rootScope.log.levels.verbose)
    $rootScope.log.indent(1, $rootScope.log.levels.verbose)
    dialog.showOpenDialog remote.getCurrentWindow(),
      title: 'Select Java Bin Directory'
      properties: ['openDirectory']
      defaultPath: $scope.launcherOptions.javaPath
    , (newPath) =>
      if newPath?
        $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
        return
      $scope.launcherOptions.javaPath = newPath[0]
      $scope.$apply()
      $scope.verifyJavaPath()
      $rootScope.log.outdent(1, $rootScope.log.levels.verbose)


  $scope.verifyJavaPath = () =>
    newPath = $rootScope.javaPath
    $rootScope.log.verbose "Verifiying Java path"
    $rootScope.log.indent(1, $rootScope.log.levels.verbose)

    if !newPath  # blank path uses bundled java instead
      $scope.launcherOptions.invalidJavaPath = false
      $scope.launcherOptions.javaPathStatus = "-- Using bundled Java version --"

      $rootScope.log.debug "Using bundled Java"
      $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
      return

    newPath = path.resolve(newPath)

    if fileExists( path.join(newPath, "java") )  || # osx+linux
       fileExists( path.join(newPath, "java.exe") ) # windows
      $scope.launcherOptions.javaPathStatus = "-- Using custom Java install --"
      $scope.launcherOptions.invalidJavaPath  = false
      $rootScope.log.debug "Using custom Java"
      $rootScope.log.indent()
      $rootScope.log.entry "path: #{newPath}"
      $rootScope.log.outdent()

      $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
      return

    $scope.launcherOptions.invalidJavaPath = true
    $rootScope.log.warning "Invalid Java path specified"
    $rootScope.log.indent()
    $rootScope.log.entry      "path: #{newPath}"
    $rootScope.log.outdent()
    $rootScope.log.debug    "Using bundled Java as a fallback"
    $rootScope.log.outdent(1, $rootScope.log.levels.verbose)


  $scope.launch = (dedicatedServer = false) =>
    $rootScope.log.event "Launching game"
    $rootScope.log.indent(1, $rootScope.log.levels.verbose)
    loadMemorySettings()
    $scope.verifyJavaPath()

    customJavaPath = null

    # Use the custom java path if it's set and valid
    if $rootScope.javaPath && not $scope.launcherOptions.invalidJavaPath
      customJavaPath = $rootScope.javaPath  # `$scope.launcherOptions.javaPath` isn't set right away.
      $rootScope.log.info "Using custom Java path"
    else
      $rootScope.log.info "Using bundled Java"

    installDir = path.resolve $scope.$parent.installDir
    starmadeJar = path.resolve "#{installDir}/StarMade.jar"
    if process.platform == 'darwin'
      appDir = path.dirname(process.execPath)
      javaBinDir = customJavaPath || path.join path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(process.execPath))))), 'MacOS', 'dep', 'java', javaJreDirectory, 'bin'
    else
      javaBinDir = customJavaPath || path.join path.dirname(process.execPath), "dep/java/#{javaJreDirectory}/bin"
    javaExec = path.join javaBinDir, 'java'

    # attach with --steam or --attach; --detach overrides
    detach = (!$rootScope.steamLaunch && !$rootScope.attach) || $rootScope.detach

    # Standard IO:  pipe if debugging and attaching to the process
    stdio  = 'inherit'
    stdio  = 'pipe' if ($rootScope.captureGame && !detach)

    $rootScope.log.info "Using Java bin path: #{javaBinDir}"
    $rootScope.log.info "Child process: " + if detach then 'detached' else 'attached'


    # Argument builder
    args = []
    args.push('-verbose:jni')                    if $rootScope.verbose
    args.push('-Djava.net.preferIPv4Stack=true')
    args.push("-Xmn#{$scope.memory.earlyGen}M")
    args.push("-Xms#{$scope.memory.initial}M")
    args.push("-Xmx#{$scope.memory.max}M")
    args.push('-Xincgc')
    args.push('-server')                         if (os.arch() == "x64")
    args.push('-jar')
    args.push(starmadeJar)
    args.push('-force')                      unless dedicatedServer
    args.push('-server')                         if dedicatedServer
    args.push('-gui')                            if dedicatedServer
    args.push("-port:#{$scope.serverPort}")
    args.push("-auth #{accessToken.get()}")      if accessToken.get()?


    # Debug output
    $rootScope.log.debug "command:"
    command = javaExec + " " + args.join(" ")
    $rootScope.log.indent()
    $rootScope.log.debug cmd_slice  for cmd_slice in command.match /.{1,128}/g
    $rootScope.log.outdent()

    $rootScope.log.debug "options:"
    $rootScope.log.indent()
    $rootScope.log.debug "cwd: #{installDir}"
    $rootScope.log.debug "stdio: #{stdio}"
    $rootScope.log.debug "detached: #{detach}"

    $rootScope.log.verbose "Environment:"
    $rootScope.log.indent()
    $rootScope.log.verbose "  #{envvar} = #{process.env[envvar]}"  for envvar in Object.keys(process.env)
    $rootScope.log.outdent()
    $rootScope.log.outdent()



    # Spawn game process
    child = spawn javaExec, args,
      cwd:      installDir
      stdio:    stdio
      detached: detach


    if detach
      $rootScope.log.event "Launched game. Exiting"
      remote.require('app').quit()


    if ($rootScope.captureGame && !detach)
      $rootScope.log.event "Monitoring game output"

      child.stdout.on 'data', (data) ->
        str = ""
        str += String.fromCharCode(char)  for char in data
        $rootScope.log.indent(1,  $rootScope.log.levels.game)
        $rootScope.log.game str
        $rootScope.log.outdent(1, $rootScope.log.levels.game)

      child.stderr.on 'data', (data) =>
        str = ""
        str += String.fromCharCode(char)  for char in data

        $rootScope.log.indent(1,  $rootScope.log.levels.game)
        $rootScope.log.game(str, $rootScope.log.levels.game)
        $rootScope.log.outdent(1,  $rootScope.log.levels.game)

      child.on 'close', (code) =>
        $rootScope.log.indent(1,  $rootScope.log.levels.game)
        $rootScope.log.event "Game process exited with code #{code}"
        $rootScope.log.outdent(1,  $rootScope.log.levels.game)


    child.on 'close', ->
      $rootScope.log.event "Game closed. Exiting"
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
