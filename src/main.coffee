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

# Controllers
require('./controllers/news')

# Directives
require('./directives/closeButton')
require('./directives/minimizeButton')
require('./directives/newsBody')

# Services
