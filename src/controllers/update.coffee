'use strict'

angular = require('angular')
remote = require('remote')

electronApp = remote.require('app')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($filter, $scope, paths, updater) ->
  $scope.versions = []

  $scope.$watch 'branch', (newVal) ->
    localStorage.setItem 'branch', newVal
    updater.getVersions newVal
      .then (versions) ->
        $scope.versions = $filter('orderBy')(versions, '-build')
        $scope.selectedVersion = 0
      , ->
        $scope.versions = null
        $scope.selectedVersion = null

  $scope.$watch 'installDir', (newVal) ->
    localStorage.setItem 'installDir', newVal

  $scope.branch = localStorage.getItem('branch') || 'release'
  $scope.installDir = localStorage.getItem('installDir') || paths.gameData

  $scope.update = ->
    updater.update($scope.versions[$scope.selectedVersion], $scope.installDir)
