'use strict'

app = angular.module 'launcher'

app.directive 'faqEntry', ->
  restrict: 'E'
  replace: true
  transclude: true
  templateUrl: 'templates/faqEntry.html'
  scope:
    question: '@'
    note: '@'
  link: (scope) ->
    scope.expanded = false
