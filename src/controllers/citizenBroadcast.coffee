'use strict'

app = angular.module 'launcher'

app.controller 'CitizenBroadcastCtrl', ($scope, $sce, citizenBroadcastApi, $rootScope) ->
  citizenBroadcastApi.get().then (response) ->
    return unless response.data?

    $scope.message = $sce.trustAsHtml response.data
    $scope.unread = true
