'use strict'

app = angular.module 'launcher'

app.directive 'closeButton', ->
  restrict: 'E'
  replace: true
  template: '<a ng-click="close()" ng-transclude></a>'
  transclude: true
  link: (scope) ->
    scope.close = ->
      window.close()
