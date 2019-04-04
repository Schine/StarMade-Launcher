'use strict'

shell = require('electron').shell

app = angular.module 'launcher'

app.directive 'newsBody', ->
  restrict: 'E'
  replace: true
  transclude: true
  template: '<div class="body" ng-transclude></div>'
  link: (scope, element) ->
    scope.$watch ->
      element.find('a').length
    , ->
      element.find('a').on 'click', (e) ->
        e.preventDefault()
        shell.openExternal angular.element(this).attr 'href'
