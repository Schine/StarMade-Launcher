'use strict'

angular = require('angular')
ipc = require('ipc')

app = angular.module 'launcher'

app.controller 'AuthCtrl', ($scope, api) ->
  $scope.startAuth = ->
    ipc.send 'start-auth', api.getAuthorizeUrl()

app.controller 'AuthTokenCtrl', ($state, $stateParams, accessToken, api) ->
  accessToken.set $stateParams.response.match(/^(.*?)&/)[1]
  api.getCurrentUser()
    .success (data) ->
      $rootScope.currentUser = data

  $state.go 'news'
