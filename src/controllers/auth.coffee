'use strict'

angular = require('angular')
ipc = require('ipc')

app = angular.module 'launcher'

app.controller 'AuthCtrl', ($scope, api) ->
  $scope.startAuth = ->
    ipc.send 'start-auth', api.getAuthorizeUrl()
