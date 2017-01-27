'use strict'

os         = require('os')
fs         = require('fs')
path       = require('path')
spawn      = require('child_process').spawn
remote     = require('remote')

dialog     = remote.require('dialog')

util       = require('../util')
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


app.controller 'LaunchCtrl', ($scope, $rootScope, $timeout, accessToken, settings) ->

  # Load launch settings from storage, or set the defaults
  $scope.serverPort = localStorage.getItem('serverPort') || 4242   # TODO: Move to `settings`

  if not $rootScope.alreadyExecuted "Loading launch options"
    $rootScope.log.event "Loading launch options"
    $rootScope.log.indent.entry "serverPort: #{$scope.serverPort}"



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


  $scope.steamLaunch = ->
    return $rootScope.steamLaunch

  $scope.buildVersion = ->
    return $rootScope.buildVersion




  $scope.launch = (dedicatedServer = false) =>
   if not settings.isReady()
      #! Possible race condition that will very likely never happen.  If it does, a second attempt should succeed.
      $rootScope.log.important "Settings not yet ready"
      return

    $rootScope.log.event "Launching game"


    # Use the custom java path if it's set and valid
    customJavaPath = null
    if settings.java.path
      customJavaPath = settings.java.path
      $rootScope.log.info "Using custom Java"
    else
      $rootScope.log.info "Using bundled Java"

    installDir = path.resolve $scope.$parent.installDir
    starmadeJar = path.resolve "#{installDir}/StarMade.jar"
    if process.platform == 'darwin'
      appDir = path.dirname(process.execPath)
      javaBinDir = customJavaPath || path.join path.dirname(path.dirname(path.dirname(path.dirname(path.dirname(process.execPath))))), 'MacOS', 'dep', 'java', javaJreDirectory, 'bin'
    else
      javaBinDir = customJavaPath || path.join path.dirname(process.execPath), "dep/java/#{javaJreDirectory}/bin"

    # Use the javaw binary (with extension) on Windows
    if process.platform == 'win32'
      javaExec = path.join javaBinDir, 'javaw.exe'
    else
      javaExec = path.join javaBinDir, 'java'

    # attach with --steam or --attach; --detach overrides
    detach = (!$rootScope.steamLaunch && !$rootScope.attach) || $rootScope.detach

    # Standard IO:  pipe if debugging and attaching to the process
    stdio  = 'inherit'
    stdio  = 'pipe' if ($rootScope.captureGame && !detach)

    $rootScope.log.indent.entry "bin path: #{javaBinDir}"
    $rootScope.log.info "Child process: " + if detach then 'detached' else 'attached'


    $rootScope.log.info "Custom java args:"
    $rootScope.log.indent.entry settings.java.args

    # Argument builder
    args = []
    # JVM args
    args.push('-verbose:jni')                    if $rootScope.verbose
    args.push('-Djava.net.preferIPv4Stack=true')
    args.push("-Xmn#{settings.memory.earlyGen}M")
    args.push("-Xms#{settings.memory.initial}M")
    args.push("-Xmx#{settings.memory.max}M")
    # Custom args
    args.push arg  for arg in settings.java.args.split(" ")
    # Jar args
    args.push('-jar')
    args.push(starmadeJar)
    args.push('-force')                      unless dedicatedServer
    args.push('-server')                         if dedicatedServer
    args.push('-gui')                            if dedicatedServer
    args.push("-port:#{$scope.serverPort}")
    args.push("-auth #{accessToken.get()}")      if accessToken.get()?


    # Debug output
    $rootScope.log.debug "Command:"
    command = javaExec + " " + args.join(" ")
    $rootScope.log.indent.debug  cmd_slice  for cmd_slice in command.match /.{1,128}/g

    $rootScope.log.debug "Options:"
    $rootScope.log.indent()
    $rootScope.log.debug   "cwd: #{installDir}"
    $rootScope.log.debug   "stdio: #{stdio}"
    $rootScope.log.debug   "detached: #{detach}"
    $rootScope.log.verbose "Environment:"
    $rootScope.log.indent.verbose "  #{envvar} = #{process.env[envvar]}"  for envvar in Object.keys(process.env)
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
        $rootScope.log.indent.game str

      child.stderr.on 'data', (data) =>
        str = ""
        str += String.fromCharCode(char)  for char in data

        $rootScope.log.indent.game str

      child.on 'close', (code) =>
        $rootScope.log.indent.event("Game process exited with code #{code}", $rootScope.log.levels.game)


    child.on 'close', ->
      $rootScope.log.event "Game closed. Exiting"
      remote.require('app').quit()

    remote.getCurrentWindow().hide()
