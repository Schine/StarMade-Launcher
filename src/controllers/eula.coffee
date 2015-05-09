'use strict'

angular = require('angular')
remote = require('remote')

app = angular.module 'launcher'

app.controller 'EulaCtrl', ($rootScope, $scope, $state, updater) ->
  updater.getEula()
    .success (data) ->
      $scope.eula = data

  $scope.accept = ->
    localStorage.setItem 'acceptedEula', true
    $rootScope.acceptedEula = true
    $state.go 'news'

  $scope.decline = ->
    remote.require('app').quit()
