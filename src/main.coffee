'use strict'

angular = require('angular')

app = angular.module 'launcher', [
  require('angular-moment')
  require('angular-ui-router')
]

app.config ($stateProvider, $urlRouterProvider) ->
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'news',
      controller: 'NewsCtrl'
      url: '/'
      templateUrl: 'templates/news.html'
    .state 'community',
      templateUrl: 'templates/community.html'

# Controllers
require('./controllers/auth')
require('./controllers/news')

# Directives
require('./directives/closeButton')
require('./directives/externalLink')
require('./directives/minimizeButton')
require('./directives/newsBody')

# Services
require('./services/api')
