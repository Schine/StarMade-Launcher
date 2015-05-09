'use strict'

angular = require('angular')
os = require('os')
remote = require('remote')
spawn = require('child_process').spawn

app = angular.module 'launcher'

app.controller 'LaunchCtrl', ($scope, paths) ->
  maxMemory = 1024
  minMemory = 512
  earlyGenMemory = 128

  maxMemory32 = 512
  minMemory32 = 516
  earlyGenMemory32 = 64

  serverMaxMemory = 1024
  serverMinMemory = 1024
  serverEarlyGenMemory = 256

  port = 4242

  $scope.launch = ->
    installDir = $scope.$parent.installDir
    starmadeJar = "#{installDir}/StarMade.jar"
    javaExec = 'java'

    if os.platform == 'win32'
      javaExec = 'javaw'

    if os.arch() == 'x64'
      spawn javaExec, [
        '-Djava.net.preferIPv4Stack=true'
        "-Xmn#{earlyGenMemory}M"
        "-Xms#{minMemory}M"
        "-Xmx#{maxMemory}M"
        '-Xincgc'
        '-jar'
        starmadeJar
        '-force'
        "-port:#{port}"
      ],
        cwd: installDir
    else
      spawn javaExec, [
        '-Djava.net.preferIPv4Stack=true'
        "-Xmn#{earlyGenMemory32}M"
        "-Xms#{minMemory32}M"
        "-Xmx#{maxMemory32}M"
        '-Xincgc'
        '-jar'
        starmadeJar
        '-force'
        "-port:#{port}"
      ],
        cwd: installDir

    remote.require('app').quit()
