'use strict'

app = angular.module 'launcher'

app.directive 'popup', ->
  restrict: 'E'
  replace: true
  transclude: true
  templateUrl: 'templates/popup.html'
  scope:
    opened: '='
    title: '@'
    type: '@'
  link: (scope, element, attributes, controller, transclude) ->
    scope.close = ->
      scope.opened = false
