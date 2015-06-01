'use strict'

angular = require('angular')
ipc = require('ipc')
path = require('path')
remote = require('remote')

electronApp = remote.require('app')

steam = require('./steam')
util = require('./util')

steam.init()

app = angular.module 'launcher', [
  require('angular-moment')
  require('angular-ui-router')
]

app.config ($httpProvider, $stateProvider, $urlRouterProvider) ->
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'authToken',
      url: '/access_token=:response'
      controller: 'AuthTokenCtrl'
    .state 'eula',
      controller: 'EulaCtrl'
      templateUrl: 'templates/eula.html'
    .state 'news',
      controller: 'NewsCtrl'
      templateUrl: 'templates/news.html'
    .state 'community',
      templateUrl: 'templates/community.html'
    .state 'player',
      controller: 'PlayerCtrl'
      templateUrl: 'templates/player.html'
    .state 'update',
      controller: 'UpdateCtrl'
      templateUrl: 'templates/update.html'

  $httpProvider.interceptors.push 'tokenInterceptor'

app.constant 'paths',
  gameData: "#{electronApp.getPath('appData')}/StarMade/Game"
  launcherData: "#{electronApp.getPath('userData')}"

app.run ($q, $rootScope, $state, accessToken, api, paths, refreshToken) ->
  rememberMe = util.parseBoolean localStorage.getItem 'rememberMe'

  $rootScope.startAuth = ->
    ipc.send 'start-auth'

  ipc.on 'finish-auth', (args) ->
    $rootScope.$apply (scope) ->
      if args.playerName?
        scope.playerName = args.playerName
        localStorage.setItem 'playerName', scope.playerName
      else
        accessToken.set args.access_token
        refreshToken.set args.refresh_token
        api.getCurrentUser()
          .success (data) ->
            scope.currentUser = data.user
            scope.playerName = scope.currentUser.username
            localStorage.setItem 'playerName', scope.playerName

      remote.getCurrentWindow().show()

  $rootScope.$on '$locationChangeStart', ->
    # Remove authentication information unless we are told to remember it
    unless rememberMe
      accessToken.delete()
      refreshToken.delete()

  if api.isAuthenticated()
    if !rememberMe || !refreshToken?
      accessToken.delete()
      refreshToken.delete()
      $rootScope.startAuth()
    else
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
      getCurrentUser()
  else
    $rootScope.startAuth()

  unless localStorage.getItem('branch')?
    localStorage.setItem 'branch', 'release'

  unless localStorage.getItem('installDir')?
    localStorage.setItem 'installDir', paths.gameData

  $rootScope.acceptedEula = localStorage.getItem 'acceptedEula'

  if $rootScope.acceptedEula
    $state.go 'news'
  else
    $state.go 'eula'

# Controllers
require('./controllers/eula')
require('./controllers/launch')
require('./controllers/news')
require('./controllers/update')

# Directives
require('./directives/closeButton')
require('./directives/externalLink')
require('./directives/minimizeButton')
require('./directives/newsBody')
require('./directives/progressBar')

# Services
require('./services/Checksum')
require('./services/Version')
require('./services/accessToken')
require('./services/api')
require('./services/refreshToken')
require('./services/tokenInterceptor')
require('./services/updater')
require('./services/updaterProgress')
