'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'CitizenBroadcastCtrl', ($scope, $sce) ->
  $scope.message = $sce.trustAsHtml 'Attention StarMade citizens,<br><br>You all are awesome.'
  $scope.unread = false
