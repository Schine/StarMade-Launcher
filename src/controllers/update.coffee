'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($scope, updater) ->
  $scope.versions = []

  $scope.$watch 'branch', (newVal) ->
    localStorage.setItem 'branch', newVal
    updater.getVersions newVal
      .then (versions) ->
        $scope.versions = versions
        $scope.selectedVersion = 0
      , ->
        $scope.versions = null
        $scope.selectedVersion = null

  $scope.branch = localStorage.getItem 'branch'
