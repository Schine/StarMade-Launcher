'use strict'

version = "0.0.5"

ipc = require('ipc')
path = require('path')
remote = require('remote')
shell = require('shell')
spawn = require('child_process').spawn

electronApp = remote.require('app')

util = require('./util')

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
  argv = remote.getGlobal('argv')
  rememberMe = util.parseBoolean localStorage.getItem 'rememberMe'

  $rootScope.version = version

  $rootScope.openDownloadPage = ->
    shell.openExternal 'http://star-made.org/download'

  $rootScope.openLicenses = ->
    ipc.send 'open-licenses'

  $rootScope.openSteamLink = ->
    shell.openExternal 'https://registry.star-made.org/profile/steam_link'

  $rootScope.startAuth = ->
    $rootScope.currentUser = null
    accessToken.delete()
    refreshToken.delete()
    ipc.send 'start-auth'

  $rootScope.switchUser = ->
    $rootScope.launcherOptions = false
    $rootScope.startAuth()


  getCurrentUser = ->
    api.getCurrentUser()
      .success (data) ->
        $rootScope.currentUser = data.user
        $rootScope.playerName = $rootScope.currentUser.username
        remote.getCurrentWindow().show()
      .error (data, status) ->
        if status == 401
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
          console.info 'Updating launcher...'

          launcherDir = process.cwd()
          launcherExec = null
          if process.platform == 'darwin'
            launcherExec = path.join launcherDir, 'Electron'
          else
            launcherExec = path.join launcherDir, 'starmade-launcher'
            launcherExec += '.exe' if process.platform == 'win32'

          ipc.send 'open-updating'
          ipc.once 'updating-opened', ->
            updater.updateLauncher(versions[0], launcherDir)
              .then ->
                console.info 'Launcher updated! Restarting...'
                child = spawn launcherExec, [],
                  detached: true
                electronApp.quit()
              , (err) ->
                console.error 'Updating the launcher failed!'
                console.error err
                remote.showErrorBox('Launcher update failed', 'The launcher failed to update.')
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

            if !data.user.steam_link? && steam.initialized && !localStorage.getItem('steamLinked')?
              steamId = steam.steamId().toString()
              api.get "profiles/steam_links/#{steamId}"
                .success ->
                  # Current Steam account is already linked
                  remote.getCurrentWindow().show()
                .error (data, status) ->
                  if status == 404
                    # Steam account not linked
                    ipc.send 'start-steam-link'
                  else
                    console.warn "Unable to determine status of Steam account: #{steamId}"
                    remote.getCurrentWindow().show()
            else
              remote.getCurrentWindow().show()

  $rootScope.$on '$locationChangeStart', ->
    # Remove authentication information unless we are told to remember it
    unless rememberMe
      accessToken.delete()
      refreshToken.delete()

  $rootScope.nogui = argv.nogui
  if !argv.nogui
    if api.isAuthenticated()
      if !rememberMe || !refreshToken?
        $rootScope.startAuth()
      else
        getCurrentUser()
    else
      # launcherAutoupdate()
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
