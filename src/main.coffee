'use strict'

angular = require('angular')

app = angular.module 'launcher', [
  require('angular-ui-router')
]

app.config ($stateProvider, $urlRouterProvider) ->
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'main',
      url: '/'
      templateUrl: 'templates/main.html'

# Controllers

# Directives
require('./directives/closeButton')
require('./directives/minimizeButton')

# Services
