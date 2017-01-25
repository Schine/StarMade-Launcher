'use strict'

app = angular.module 'launcher'

app.directive 'settingsDialog', ($rootScope, settings) ->
  return {
    restrict:    'E'
    replace:     true
    transclude:  true
    templateUrl: 'templates/popup.html'
    scope:
      opened: '='
      title:  '@'
      type:   '@'
    link: (scope, element, attributes, controller, transclude) ->
      scope.close = ->
        settings.dialog.hide()
  }