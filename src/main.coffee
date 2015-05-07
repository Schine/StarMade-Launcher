'use strict'

angular = require('angular')

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
    .state 'news',
      controller: 'NewsCtrl'
      url: '/'
      templateUrl: 'templates/news.html'
    .state 'community',
      templateUrl: 'templates/community.html'
    .state 'update',
      controller: 'UpdateCtrl'
      templateUrl: 'templates/update.html'

  $httpProvider.interceptors.push 'tokenInterceptor'

app.run ($rootScope, accessToken, api) ->
  if api.isAuthenticated()
    api.getCurrentUser()
      .success (data) ->
        $rootScope.currentUser = data
      .error (data, status) ->
        if status = 401
          accessToken.delete()

# Controllers
require('./controllers/auth')
require('./controllers/news')
require('./controllers/update')

# Directives
require('./directives/closeButton')
require('./directives/externalLink')
require('./directives/minimizeButton')
require('./directives/newsBody')

# Services
require('./services/Version')
require('./services/accessToken')
require('./services/api')
require('./services/tokenInterceptor')
require('./services/updater')
