'use strict'

angular = require('angular')
os = require('os')
path = require('path')
remote = require('remote')
spawn = require('child_process').spawn
util = require('../util')

pkg = require(path.join(path.dirname(path.dirname(__dirname)), 'package.json'))
javaVersion = pkg.javaVersion
javaJreDirectory = util.getJreDirectory javaVersion

app = angular.module 'launcher'

app.controller 'LaunchCtrl', ($scope, accessToken, paths) ->
  defaults =
    ia32:
      max: 512
      initial: 256
      earlyGen: 64
    x64:
      max: 1024
      initial: 512
      earlyGen: 128

  port = 4242

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

  $scope.launch = (dedicatedServer = false) ->
    loadClientOptions()

    installDir = path.resolve $scope.$parent.installDir
    starmadeJar = path.resolve "#{installDir}/StarMade.jar"
    if process.platform == 'darwin'
      appDir = path.dirname(process.execPath)
      javaBinDir = path.join path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(process.execPath))))), 'MacOS', 'dep', 'java', javaJreDirectory, 'bin'
    else
      javaBinDir = path.resolve "dep/java/#{javaJreDirectory}/bin"
    javaExec = path.join javaBinDir, 'java'

    child = spawn javaExec, [
      '-Djava.net.preferIPv4Stack=true'
      "-Xmn#{$scope.memory.earlyGen}M"
      "-Xms#{$scope.memory.initial}M"
      "-Xmx#{$scope.memory.max}M"
      '-Xincgc'
      '-jar'
      starmadeJar
      '-force' unless dedicatedServer
      '-server' if dedicatedServer
      '-gui' if dedicatedServer
      "-port:#{port}"
      "-auth #{accessToken.get()}" if accessToken.get()?
    ],
      cwd: installDir
      stdio: 'inherit'

    child.on 'close', ->
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
