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
  maxMemory = 1024
  minMemory = 512
  earlyGenMemory = 128

  maxMemory32 = 512
  minMemory32 = 256
  earlyGenMemory32 = 64

  serverMaxMemory = 1024
  serverMinMemory = 1024
  serverEarlyGenMemory = 256

  port = 4242

  $scope.launch = ->
    installDir = path.resolve $scope.$parent.installDir
    starmadeJar = path.resolve "#{installDir}/StarMade.jar"
    if process.platform == 'darwin'
      appDir = path.dirname(process.execPath)
      javaBinDir = path.join path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(process.execPath))))), 'MacOS', 'dep', 'java', javaJreDirectory, 'bin'
    else
      javaBinDir = path.resolve "dep/java/#{javaJreDirectory}/bin"
    javaExec = path.join javaBinDir, 'java'

    # TODO: Find a way to detect the arch that isn't based on the current
    # process
    if os.arch() == 'x64'
      child = spawn javaExec, [
        '-Djava.net.preferIPv4Stack=true'
        "-Xmn#{earlyGenMemory}M"
        "-Xms#{minMemory}M"
        "-Xmx#{maxMemory}M"
        '-Xincgc'
        '-jar'
        starmadeJar
        '-force'
        "-port:#{port}"
        "-auth #{accessToken.get()}" if accessToken.get()?
      ],
        cwd: installDir
        stdio: 'inherit'
    else
      child = spawn javaExec, [
        '-Djava.net.preferIPv4Stack=true'
        "-Xmn#{earlyGenMemory32}M"
        "-Xms#{minMemory32}M"
        "-Xmx#{maxMemory32}M"
        '-Xincgc'
        '-jar'
        starmadeJar
        '-force'
        "-port:#{port}"
        "-auth #{accessToken.get()}" if accessToken.get()?
      ],
        cwd: installDir
        stdio: 'inherit'

    child.on 'close', ->
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
