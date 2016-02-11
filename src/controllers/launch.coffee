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



app.controller 'LaunchCtrl', ($scope, $rootScope, accessToken) ->
  totalRam = Math.floor( os.totalmem()/1024/1024 )  # bytes -> mb
  defaults =
    ia32:
      earlyGen:   64
      initial:   256
      max:       512      # slider value
      ceiling:  2048      # slider max
    x64:
      earlyGen:  128
      initial:   512
      max:      1536      # slider value
      ceiling:  totalRam  # slider max

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

  # ensure Max >= initial+earlyGen
  updateMemorySlider = (earlyGen, initial) ->
    console.log("updateMemorySlider(): earlyGen = #{earlyGen} (#{$scope.memory.earlyGen})")
    console.log("updateMemorySlider(): initial  = #{initial}  (#{$scope.memory.initial})")

    earlyGen = $scope.memory.earlyGen  if typeof earlyGen == "undefined"
    initial  = $scope.memory.initial   if typeof initial  == "undefined"

    updateMemoryFloor()  # update floor whenever initial/earlyGen change
    console.log("Memory: #{$scope.memory.floor} <= #{$scope.memory.max} <= #{$scope.memory.ceiling}")
    return  if earlyGen + initial <= $scope.memory.max
    $scope.memory.max = Math.max(earlyGen + initial,  $scope.memory.floor)
    console.log("Memory: updated max to #{$scope.memory.max}")


  # max memory should be >= early+initial, and a multiple of 256
  updateMemoryFloor = () ->
    min = $scope.memory.earlyGen + $scope.memory.initial
    $scope.memory.floor = Math.ceil(min/256)*256 || 256  # 256 minimum

  # Load memory settings from storage or set the defaults
  loadMemorySettings = ->
    $scope.memory =
      max:      Number(localStorage.getItem('maxMemory'))      || Number(defaults[os.arch()].max)
      initial:  Number(localStorage.getItem('initialMemory'))  || Number(defaults[os.arch()].initial)
      earlyGen: Number(localStorage.getItem('earlyGenMemory')) || Number(defaults[os.arch()].earlyGen)
      ceiling:  Number( defaults[os.arch()].ceiling )
    # $scope.memory.floor = Math.ceil(($scope.memory.earlyGen + $scope.memory.initial)/256)*256 || 256  # 256 minimum
    updateMemorySlider() # Fix the zero'd slider knob bug

  $scope.openClientOptions = ->
    loadMemorySettings()
    $scope.clientMemoryOptions = true

  $scope.closeClientOptions = ->
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

    console.log("| using java bin path: #{javaBinDir}")
    console.log("child process: " + if detach then 'detached' else 'attached')

    child = spawn javaExec, [
      '-Djava.net.preferIPv4Stack=true'
      "-Xmn#{$scope.memory.earlyGen}M"
      "-Xms#{$scope.memory.initial}M"
      "-Xmx#{$scope.memory.max}M"
      '-Xincgc'
      '-server'
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
