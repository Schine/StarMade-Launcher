'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($scope, updater) ->
  updater.getVersions()
    .then (versions) ->
      $scope.versions = versions
