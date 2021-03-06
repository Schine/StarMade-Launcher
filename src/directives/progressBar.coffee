'use strict'

app = angular.module 'launcher'

app.directive 'progressBar', ->
  restrict: 'E'
  replace: true
  transclude: true
  templateUrl: 'templates/progressBar.html'
  scope:
    curValue: '@curValue'
    maxValue: '@maxValue'
  link: (scope, element) ->
    updatePercent = ->
      scope.percent = scope.curValue / scope.maxValue * 100.0
      scope.width = 208.0 * (scope.percent / 100.0)

    scope.$watch 'curValue', updatePercent
    scope.$watch 'maxValue', updatePercent

    updatePercent()
