'use strict'

remote = require('remote')

app = angular.module 'launcher'

app.directive 'minimizeButton', ->
  restrict: 'E'
  replace: true
  template: '<a ng-click="minimize()" ng-transclude></a>'
  transclude: true
  link: (scope) ->
    scope.minimize = ->
      remote.getCurrentWindow().minimize()
