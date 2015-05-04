'use strict'

angular = require('angular')

app = angular.module 'launcher', [
  require('angular-moment')
  require('angular-ui-router')
]

app.config ($stateProvider, $urlRouterProvider) ->
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
require('./services/updater')
