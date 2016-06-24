'use strict'

os = require('os')
fs = require('fs')
path = require('path')
remote = require('remote')
dialog = remote.require('dialog')
spawn = require('child_process').spawn
util = require('../util')

pkg = require(path.join(path.dirname(path.dirname(__dirname)), 'package.json'))
javaVersion = pkg.javaVersion
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
  defaults =
    ia32:
      earlyGen:   64
      initial:   256
      max:       512      # initial memory.max value
      ceiling:  2048      # maximum value allowed
    x64:
      earlyGen:  128
      initial:   512
      max:      2048      # initial memory.max value
      ceiling:  totalRam  # maximum value allowed

  $scope.launcherOptions = {}

  # restore previous settings, or use the defaults
  $scope.serverPort               = localStorage.getItem('serverPort') || 4242
  $scope.launcherOptions.javaPath = localStorage.getItem('javaPath')   || ""


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
    # nearest pow2 or memory ceiling (round down)
    $scope.memory.max = Math.min(nearestPow2(newVal), $scope.memory.ceiling)

    # Allow snapping to end of slider, power of 2 or not
    if $scope.memory.max != $scope.memory.ceiling
      if newVal >= ($scope.memory.max + $scope.memory.ceiling) / 2
        $scope.memory.max = $scope.memory.ceiling


    $scope.memory.slider = $scope.memory.max
    update_slider_class()
    # console.log("Snapping from #{newVal} to #{$scope.memory.max}")


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
  nearestPow2 = (val) ->
    # Memoize
    if typeof pow2_lower_bound == "number"  &&  typeof pow2_upper_bound == "number"  # Skip entire block if bounds are undefined/incorrect
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

    updateMemoryFloor()  # update floor whenever initial/earlyGen change

    $scope.memory.max    = Math.max($scope.memory.floor, $scope.memory.max)
    $scope.memory.slider = $scope.memory.max
    update_slider_class() # toggles green and labels when at a power of 2

    # Workaround for Angular's range bug  (https://github.com/angular/angular.js/issues/6726)
    $timeout ->
      document.getElementById("maxMemorySlider").value = $scope.memory.max


  # max memory should be >= early+initial, and a power of 2
  updateMemoryFloor = () ->
    # deleting the contents of the `earlyGen` and/or `initial` textboxes causes problems.  setting a min value here fixes it.
    val = Math.max(256, $scope.memory.earlyGen + $scope.memory.initial)

    # Next power of 2 (ceil)
    val--  # allows powers of 2
    min = 2
    # left-shift `min` the number of bits in `val`, plus 1 (next power of 2)
    while val >>= 1
      min <<= 1

    $scope.memory.floor = Math.max(min, 256)  # 256 minimum


  # Load memory settings from storage or set the defaults
  loadMemorySettings = ->
    $scope.memory =
      max:      Number(localStorage.getItem('maxMemory'))      || Number(defaults[os.arch()].max)
      initial:  Number(localStorage.getItem('initialMemory'))  || Number(defaults[os.arch()].initial)
      earlyGen: Number(localStorage.getItem('earlyGenMemory')) || Number(defaults[os.arch()].earlyGen)
      ceiling:  Number( defaults[os.arch()].ceiling )
      step:     256  # Used by #maxMemoryInput.  See AngularJS workaround in $scope.closeClientOptions() below for why this isn't hardcoded.
    updateMemorySlider()


  $scope.openClientOptions = ->
    loadMemorySettings()
    $scope.clientMemoryOptions = true

  $scope.closeClientOptions = ->
    $scope.memory.step = 1    # AngularJS workaround: specifying non-multiples of {{step}} throws an error upon hiding the control.  hacky workaround.
    $scope.clientMemoryOptions = false


  $scope.saveClientOptions = ->
    localStorage.setItem 'maxMemory',      $scope.memory.max
    localStorage.setItem 'initialMemory',  $scope.memory.initial
    localStorage.setItem 'earlyGenMemory', $scope.memory.earlyGen
    $scope.closeClientOptions()


  $scope.steamLaunch = ->
    return $rootScope.steamLaunch

  $scope.buildVersion = ->
    return $rootScope.buildVersion


  $scope.$watch 'launcherOptions.javaPath', (newVal) ->
    localStorage.setItem 'javaPath', newVal
    $rootScope.javaPath = newVal


  $scope.$watch 'launcherOptionsWindow', (visible) ->
    $scope.verifyJavaPath()  if visible

  $scope.launcherOptions.javaPathBrowse = () =>
    dialog.showOpenDialog remote.getCurrentWindow(),
      title: 'Select Java Bin Directory'
      properties: ['openDirectory']
      defaultPath: $scope.launcherOptions.javaPath
    , (newPath) =>
      return unless newPath?
      $scope.launcherOptions.javaPath = newPath[0]
      $scope.$apply()
      $scope.verifyJavaPath()

  $scope.verifyJavaPath = () =>
    newPath = $rootScope.javaPath
    if !newPath  # blank path uses bundled java instead
      $scope.launcherOptions.invalidJavaPath = false
      $scope.launcherOptions.javaPathStatus = "-- Using bundled Java version --"
      return
    newPath = path.resolve(newPath)

    if fileExists( path.join(newPath, "java") )  || # osx+linux
       fileExists( path.join(newPath, "java.exe") ) # windows
      $scope.launcherOptions.javaPathStatus = "-- Using custom Java install --"
      $scope.launcherOptions.invalidJavaPath  = false
      return
    $scope.launcherOptions.invalidJavaPath = true

  fileExists = (pathName) ->
    pathName = path.resolve(pathName)
    try
      # since Node changes the fs.exists() functions with every version
      fs.closeSync( fs.openSync(pathName, "r") )
      return true
    catch e
      return false


  $scope.launch = (dedicatedServer = false) =>
    loadMemorySettings()

    customJavaPath = $rootScope.javaPath  # ($scope.launcherOptions.javaPath) isn't set right away.

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

    console.log("using java bin path: #{javaBinDir}")
    console.log("child process: " + if detach then 'detached' else 'attached')


    # command = javaExec + " " + [
    #   '-Djava.net.preferIPv4Stack=true'
    #   "-Xmn#{$scope.memory.earlyGen}M"
    #   "-Xms#{$scope.memory.initial}M"
    #   "-Xmx#{$scope.memory.max}M"
    #   '-Xincgc'
    #   '-server'  if (os.arch() == "x64")
    #   '-jar'
    #   starmadeJar
    #   '-force'   unless dedicatedServer
    #   '-server'      if dedicatedServer
    #   '-gui'         if dedicatedServer
    #   "-port:#{$scope.serverPort}"
    #   "-auth #{accessToken.get()}"  if accessToken.get()?
    # ].join(" ");
    
    # console.log("command: #{command}")
    # console.log(" | cwd: #{installDir}")
    # console.log(" | stdio: 'inherit'")
    # console.log(" | detached: #{detach}")



    child = spawn javaExec, [
      '-Djava.net.preferIPv4Stack=true'
      "-Xmn#{$scope.memory.earlyGen}M"
      "-Xms#{$scope.memory.initial}M"
      "-Xmx#{$scope.memory.max}M"
      '-Xincgc'
      '-server'  if (os.arch() == "x64")
      '-jar'
      starmadeJar
      '-force'   unless dedicatedServer
      '-server'      if dedicatedServer
      '-gui'         if dedicatedServer
      "-port:#{$scope.serverPort}"
      "-auth #{accessToken.get()}"  if accessToken.get()?
    ],
      cwd: installDir
      stdio: 'inherit'
      detached: detach

    remote.require('app').quit()  if detach

    child.on 'close', ->
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
