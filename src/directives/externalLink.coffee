'use strict'

angular = require('angular')
ipc = require('ipc')
shell = require('shell')

app = angular.module 'launcher'

app.directive 'externalLink', ->
  restrict: 'E'
  replace: true
  scope:
    href: '@href'
    thirdPartyWarning: '=thirdPartyWarning'
  template: '<a ng-click="openExternal()" ng-transclude></a>'
  transclude: true
  link: (scope, element) ->
    element.removeAttr 'href'

    scope.openExternal = ->
      if scope.thirdPartyWarning
        ipc.send 'third-party-warning', scope.href
      else
        shell.openExternal scope.href
