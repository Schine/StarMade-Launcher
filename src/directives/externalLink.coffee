'use strict'

remote = require('remote')
shell = require('shell')

dialog = remote.require('dialog')

app = angular.module 'launcher'

app.directive 'externalLink', ->
  restrict: 'E'
  replace: true
  scope:
    href: '@href'
    thirdPartyWarning: '=thirdPartyWarning'
  template: '<a ng-click="openExternal($event)" ng-transclude></a>'
  transclude: true
  link: (scope, element) ->
    element.removeAttr 'href'

    scope.openExternal = (event) ->
      event.preventDefault()

      if scope.thirdPartyWarning
        dialog.showMessageBox
          type: 'info'
          buttons: [
            'OK'
            'Cancel'
          ]
          title: 'Third Party Website'
          message: 'You are about to visit a third party website. Schine GmbH does not take any responsibility for any content on third party sites.'
          (response) ->
            shell.openExternal scope.href if response == 0
      else
        shell.openExternal scope.href
