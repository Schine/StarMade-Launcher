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

app.controller 'LaunchCtrl', ($scope, $rootScope, accessToken) ->
  defaults =
    ia32:
      max: 512
      initial: 256
      earlyGen: 64
    x64:
      max: 1536
      initial: 512
      earlyGen: 128

  $scope.serverPort = localStorage.getItem('serverPort') || 4242

  $scope.$watch 'serverPort', (newVal) ->
    localStorage.setItem 'serverPort', newVal

  loadClientOptions = ->
    $scope.memory =
      max: localStorage.getItem('maxMemory') || defaults[os.arch()].max
      initial: localStorage.getItem('initialMemory') || defaults[os.arch()].initial
      earlyGen: localStorage.getItem('earlyGenMemory') || defaults[os.arch()].earlyGen

  $scope.openClientOptions = ->
    loadClientOptions()

    $scope.clientMemoryOptions = true

  $scope.closeClientOptions = ->
    $scope.clientMemoryOptions = false

  $scope.saveClientOptions = ->
    localStorage.setItem 'maxMemory', $scope.memory.max
    localStorage.setItem 'initialMemory', $scope.memory.initial
    localStorage.setItem 'earlyGenMemory', $scope.memory.earlyGen
    $scope.closeClientOptions()

  $scope.steamLaunch = ->
    return $rootScope.steamLaunch

  $scope.launcherOptions = {}

  $scope.$watch 'launcherOptions.javaPath', (newVal) ->
    console.log "$watch triggered, #{newVal}"
    localStorage.setItem 'javaPath', newVal


  $scope.$watch 'launcherOptions', (visible) ->
    $scope.verifyJavaPath()  if visible

  $scope.launcherOptions.javaPathBrowse = () =>
    dialog.showOpenDialog remote.getCurrentWindow(),
      title: 'Select Java Bin Directory'
      properties: ['openDirectory']
      defaultPath: $scope.launcherOptions.javaPath
    , (newPath) =>
      return unless newPath?
      $scope.launcherOptions.javaPath = newPath[0]
      $rootScope.javaPath = newPath[0]
      $scope.$apply()
      $scope.verifyJavaPath()

  $scope.verifyJavaPath = () =>
    newPath = $scope.launcherOptions.javaPath
    console.log "verifyJavaPath: #{newPath}"
    if !newPath  # blank path uses bundled java instead
      $scope.launcherOptions.invalidJavaPath = false
      $scope.launcherOptions.javaPathStatus = "-- Using bundled Java version --"
      $scope.$apply()
      return
    newPath = path.resolve($scope.launcherOptions.javaPath)

    if fileExists( path.join(newPath, "java") )  || # osx+linux
       fileExists( path.join(newPath, "java.exe") ) # windows
      $scope.launcherOptions.javaPathStatus = "-- Using custom Java install --"
      $scope.launcherOptions.invalidJavaPath  = false
      $scope.$apply()
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

  # $scope.launcherOptions.javaPath = localStorage.getItem('javaPath') || ""



  $scope.launch = (dedicatedServer = false) =>
    loadClientOptions()

    customJavaPath = $rootScope.javaPath || $scope.launcherOptions.javaPath
    console.log("launch() javaPath: #{customJavaPath}")

    installDir = path.resolve $scope.$parent.installDir
    starmadeJar = path.resolve "#{installDir}/StarMade.jar"
    if process.platform == 'darwin'
      appDir = path.dirname(process.execPath)
      javaBinDir = customJavaPath || path.join path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(process.execPath))))), 'MacOS', 'dep', 'java', javaJreDirectory, 'bin'
    else
      javaBinDir = customJavaPath || path.join path.dirname(process.execPath), "dep/java/#{javaJreDirectory}/bin"
    javaExec = path.join javaBinDir, 'java'


    console.log("| using java bin path: #{javaBinDir}")

    child = spawn javaExec, [
      '-Djava.net.preferIPv4Stack=true'
      "-Xmn#{$scope.memory.earlyGen}M"
      "-Xms#{$scope.memory.initial}M"
      "-Xmx#{$scope.memory.max}M"
      '-Xincgc'
      '-server'
      '-jar'
      starmadeJar
      '-force' unless dedicatedServer
      '-server' if dedicatedServer
      '-gui' if dedicatedServer
      "-port:#{$scope.serverPort}"
      "-auth #{accessToken.get()}" if accessToken.get()?
    ],
      cwd: installDir
      stdio: 'inherit'

    child.on 'close', ->
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
