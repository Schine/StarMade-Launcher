'use strict'

os      = require('os')
ipc     = require('ipc')
path    = require('path')
remote  = require('remote')
shell   = require('shell')
spawn   = require('child_process').spawn

electronApp = remote.require('app')

buildHash  = require('./buildHash.js').buildHash
util       = require('./util')


pkg = require(path.join(path.dirname(__dirname), 'package.json'))

app = angular.module 'launcher', [
  require('angular-moment')
  require('angular-resource')
  require('angular-ui-router')
  'xml'
]

app.config ($httpProvider, $stateProvider, $urlRouterProvider) ->
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'authToken',
      url: '/access_token=:response'
      controller: 'AuthTokenCtrl'
    .state 'news',
      controller: 'NewsCtrl'
      templateUrl: 'templates/news.html'
    .state 'community',
      templateUrl: 'templates/community.html'
    .state 'council',
      controller: 'CouncilCtrl'
      templateUrl: 'templates/council.html'
    .state 'player',
      controller: 'PlayerCtrl'
      templateUrl: 'templates/player.html'
    .state 'support',
      templateUrl: 'templates/support.html'
    .state 'update',
      controller: 'UpdateCtrl'
      templateUrl: 'templates/update.html'

  $httpProvider.interceptors.push 'xmlHttpInterceptor'
  $httpProvider.interceptors.push 'tokenInterceptor'

app.run ($q, $rootScope, $state, $timeout, accessToken, api, refreshToken, updater) ->
  argv       = remote.getGlobal('argv')
  rememberMe = util.parseBoolean localStorage.getItem 'rememberMe'

  # Quality Assurance build?  (enables debugging)
  qa_build = false

  $rootScope.log         = require('./log-helpers')  # Logging helpers
  $rootScope.version     =   pkg.version
  $rootScope.buildHash   =   buildHash
  $rootScope.steamLaunch = !!argv.steam                                    ##TODO: change to just `steam`
  $rootScope.attach      = !!argv.attach    || !!argv['capture-game-log']  # attach the game process; default behavior with   --steam
  $rootScope.detach      = !!argv.detach                                   # detach the game process; default behavior witout --steam
  $rootScope.noUpdate    = !!argv.noupdate  || $rootScope.steamLaunch
  $rootScope.debugging   = !!argv.debugging || !!argv.verbose || qa_build
  $rootScope.verbose     = !!argv.verbose
  $rootScope.captureGame = !!argv['capture-game-log']


  $rootScope.log.raw  "StarMade Launcher v#{pkg.version} build #{buildHash}" + (if qa_build then " (QA)" else "") + "\n"
  
  $rootScope.log.info "Platform"
  $rootScope.log.indent()
  $rootScope.log.entry "OS:  #{process.platform} (#{os.arch()})"
  ##TODO: add java 32/64 info here
  $rootScope.log.entry "RAM: #{Math.floor( os.totalmem()/1024/1024 )}mb"
  $rootScope.log.entry "CWD: #{ ipc.sendSync('cwd') }"
  $rootScope.log.outdent()

  $rootScope.log.info "Launcher flags:"
  $rootScope.log.indent()
  _flags   = []
  _flags.push "--#{arg}"  for arg in Object.keys(argv).slice(1)
  _flags   = _flags.join(" ")
  $rootScope.log.entry _flags || "(None)"
  $rootScope.log.outdent()

  $rootScope.log.info "Mode:"
  $rootScope.log.indent()
  $rootScope.log.entry "Debugging: enabled" + (if $rootScope.verbose then " (verbose)" else "")  if $rootScope.debugging
  $rootScope.log.entry "Steam:     #{$rootScope.steamLaunch}"
  # attach with --steam or --attach; --detach overrides
  $rootScope.log.entry "Attach:    #{($rootScope.steamLaunch || $rootScope.attach) && !$rootScope.detach}"  ##TODO: migrate to using this in launch.coffee
  $rootScope.log.entry "capture:   #{$rootScope.captureGame}"
  $rootScope.log.outdent()



  # Prevent multiple executions, optionally within a specified cooldown
  $rootScope.alreadyExecuted = (id, cooldown=0) ->
    # Forgive me for my sins... they just keep things so clean!
    $rootScope.alreadyExecuted.ids or= {}
    cooldown += Date.now()  if cooldown > 0

    expiry = $rootScope.alreadyExecuted.ids[id]

    if not expiry?
      # Not executed yet.
      $rootScope.alreadyExecuted.ids[id] = cooldown
      return false

    # Already executed?
    return true  if expiry <= 0           # <1: only execute once
    return true  if expiry >= Date.now()  # still within cooldown

    # Yes, but out of cooldown.  Refresh ~
    $rootScope.alreadyExecuted.ids[id] = cooldown
    return false


  $rootScope.openDownloadPage = ->
    $rootScope.log.event "Opening download page: http://star-made.org/download"
    shell.openExternal 'http://star-made.org/download'

  $rootScope.openLicenses = ->
    $rootScope.log.event "Displaying licenses"
    ipc.send 'open-licenses'

  $rootScope.openSteamLink = ->
    $rootScope.log.event "opening: https://registry.star-made.org/profile/steam_link"
    shell.openExternal 'https://registry.star-made.org/profile/steam_link'

  $rootScope.startAuth = ->
    $rootScope.log.event "Displaying auth"
    $rootScope.currentUser = null
    accessToken.delete()
    refreshToken.delete()
    ipc.send 'start-auth'

  $rootScope.switchUser = ->
    $rootScope.launcherOptionsWindow = false
    $rootScope.log.event "Switching user"
    $rootScope.startAuth()


  getCurrentUser = ->
    api.getCurrentUser()
      .success (data) ->
        $rootScope.currentUser = data.user
        $rootScope.playerName = $rootScope.currentUser.username
        $rootScope.log.info  "Using saved credentials"
        $rootScope.log.entry "Username: #{$rootScope.playerName}"
        if $rootScope.steamLaunch && !localStorage.getItem('steamLinked')?
          ipc.send 'start-steam-link'
        else
          remote.getCurrentWindow().show()
      .error (data, status) ->
        if status == 401
          $rootScope.log.info  "Using saved credentials"
          $rootScope.log.event "Requesting auth token"
          refreshToken.refresh()
            .then (data) ->
              accessToken.set data.access_token
              refreshToken.set data.refresh_token

              # Try again
              getCurrentUser()
            , ->
              accessToken.delete()
              refreshToken.delete()
              $rootScope.startAuth()
        else
          $rootScope.startAuth()


  launcherAutoupdate = ->
    # Check for updates to the launcher
    $rootScope.launcherUpdating = true
    updater.getVersions('launcher')
      .then (versions) ->
        if versions[0].version != pkg.version
          $rootScope.log.update 'Updating launcher...'

          launcherDir = ipc.sendSync('cwd');  # Fetch launcher dir from main process
          launcherExec = null
          launcherAsar = null
          if process.platform == 'darwin'
            launcherAsar = path.join launcherDir, '..', 'Resources'
            launcherExec = path.join launcherDir, 'Electron'
          else
            launcherAsar = path.join launcherDir, 'resources'
            launcherExec = path.join launcherDir, 'starmade-launcher'
            launcherExec += '.exe' if process.platform == 'win32'


          ipc.send 'open-updating'
          ipc.once 'updating-opened', ->
            updater.updateLauncher(versions[0], launcherDir)
              .then ->
                $rootScope.log.entry "Launcher updated!"
                $rootScope.log.end   "Restarting"
                $rootScope.log.indent.verbose "launcher exec path: #{launcherExec}"

                ipc.send 'close-updating'
                $rootScope.launcherUpdating = false
                child = spawn launcherExec, [],
                  detached: true
                electronApp.quit()


              , (err) ->
                $rootScope.log.error 'Launcher update failed!'
                $rootScope.log.indent.entry err

                # remote.showErrorBox('Launcher update failed', 'The launcher failed to update.')

                ipc.send 'close-updating'
                $rootScope.launcherUpdating = false
                $rootScope.startAuth()
        else
          # Delay for a second to workaround RawChannel errors
          $timeout ->
            $rootScope.launcherUpdating = false
          , 1000


  ipc.on 'finish-auth', (args) ->
    $rootScope.$apply (scope) ->
      if args.playerName?
        scope.playerName = args.playerName
        localStorage.setItem 'playerName', scope.playerName
        remote.getCurrentWindow().show()
      else
        accessToken.set args.access_token
        refreshToken.set args.refresh_token
        api.getCurrentUser()
          .success (data) ->
            scope.currentUser = data.user
            scope.playerName = scope.currentUser.username
            localStorage.setItem 'playerName', scope.playerName

            scope.steamAccountLinked = true if data.user.steam_link?

            # if $rootScope.steamLaunch && !data.user.steam_link? && steam.initialized && !localStorage.getItem('steamLinked')?
            if $rootScope.steamLaunch && !localStorage.getItem('steamLinked')?
              ipc.send 'start-steam-link'
              # steamId = steam.steamId().toString()
              # api.get "profiles/steam_links/#{steamId}"
              #   .success ->
              #     # Current Steam account is already linked
              #     remote.getCurrentWindow().show()
              #   .error (data, status) ->
              #     if status == 404
              #       # Steam account not linked
              #       ipc.send 'start-steam-link'
              #     else
              #       $rootScope.log.warning "Unable to determine status of Steam account: #{steamId}"
              #       remote.getCurrentWindow().show()
            else
              remote.getCurrentWindow().show()

  $rootScope.$on '$locationChangeStart', ->
    # Remove authentication information unless we are told to remember it
    unless rememberMe
      accessToken.delete()
      refreshToken.delete()

  $rootScope.nogui = argv.nogui

  if !argv.nogui
    launcherAutoupdate()  if !$rootScope.noUpdate
    if api.isAuthenticated()
      if !rememberMe || !refreshToken?
        $rootScope.startAuth()
      else
        getCurrentUser()
    else
      $rootScope.startAuth()
  $state.go 'news'



# Controllers
require('./controllers/citizenBroadcast')
require('./controllers/council')
require('./controllers/launch')
require('./controllers/news')
require('./controllers/update')

# Directives
require('./directives/closeButton')
require('./directives/externalLink')
require('./directives/faqEntry')
require('./directives/minimizeButton')
require('./directives/newsBody')
require('./directives/popup')
require('./directives/progressBar')

# Filters
require('./filters/ordinalDate')

# Services
require('./services/Checksum')
require('./services/NewsSidebarEntry')
require('./services/Version')
require('./services/accessToken')
require('./services/api')
require('./services/refreshToken')
require('./services/tokenInterceptor')
require('./services/updater')
require('./services/updaterProgress')
