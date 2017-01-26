'use strict'

app = angular.module 'launcher'

app.controller 'CitizenBroadcastCtrl', ($scope, $sce, citizenBroadcastApi, $rootScope) ->
  citizenBroadcastApi.get().then (message) ->
    return unless message?

    $scope.message = $sce.trustAsHtml message
    $scope.unread = true
