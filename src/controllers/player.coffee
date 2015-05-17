'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'PlayerCtrl', ($rootScope, $scope, api) ->
  $rootScope.$watch 'currentUser', (newVal) ->
    if newVal
      $scope.playerName = newVal.username

  $scope.$watch 'playerName', (newVal) ->
    localStorage.setItem 'playerName', newVal

  if $rootScope.currentUser
    $scope.playerName = $rootScope.currentUser.username
  else
    $scope.playerName = localStorage.getItem('playerName') || 'Dave'
