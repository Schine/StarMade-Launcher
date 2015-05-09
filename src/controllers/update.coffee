'use strict'

angular = require('angular')
remote = require('remote')

electronApp = remote.require('app')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($scope, paths, updater) ->
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

  $scope.$watch 'installDir', (newVal) ->
    localStorage.setItem 'installDir', newVal

  $scope.branch = localStorage.getItem('branch') || 'release'
  $scope.installDir = localStorage.getItem('installDir') || paths.gameData

  $scope.getChecksums = (index) ->
    updater.getChecksums($scope.versions[$scope.selectedVersion].path)
      .then (checksums) ->
        console.log checksums
