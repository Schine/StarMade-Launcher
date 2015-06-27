'use strict'

angular = require('angular')
remote = require('remote')

electronApp = remote.require('app')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($filter, $scope, paths, updater, updaterProgress) ->
  $scope.versions = []
  $scope.updaterProgress = updaterProgress
  $scope.status = ''

  $scope.onPlayTab = true
  $scope.onDedicatedTab = false
  $scope.updateHover = false
  $scope.launchHover = false

  $scope.showPlayTab = ->
    $scope.onPlayTab = true
    $scope.onDedicatedTab = false

  $scope.showDedicatedTab = ->
    $scope.onDedicatedTab = true
    $scope.onPlayTab = false

  $scope.updateMouseEnter = ->
    $scope.updateHover = true

  $scope.updateMouseLeave = ->
    $scope.updateHover = false

  $scope.launchMouseEnter = ->
    $scope.launchHover = true

  $scope.launchMouseLeave = ->
    $scope.launchHover = false

  updateStatus = (selectedVersion) ->
    return if $scope.versions.length == 0

    if $scope.updaterProgress.needsUpdating
      $scope.status = "You need to update for v#{$scope.versions[selectedVersion].version}"
    else
      if selectedVersion == 0
        $scope.status = 'You have the latest version for this Build Type'
      else
        $scope.status = "You are up-to-date for v#{$scope.versions[selectedVersion].version}"

  $scope.$watch 'branch', (newVal) ->
    localStorage.setItem 'branch', newVal
    $scope.switchingBranch = true
    updater.getVersions newVal
      .then (versions) ->
        $scope.switchingBranch = false
        $scope.versions = $filter('orderBy')(versions, '-build')
        $scope.versions[0].latest = '(Latest)'
        $scope.selectedVersion = 0
        updater.update($scope.versions[0], $scope.installDir, true)
      , ->
        $scope.status = 'You are offline.' unless navigator.onLine
        $scope.switchingBranch = false
        $scope.versions = []
        $scope.selectedVersion = null

  $scope.$watch 'installDir', (newVal) ->
    localStorage.setItem 'installDir', newVal

  $scope.$watch 'serverPort', (newVal) ->
    localStorage.setItem 'serverPort', newVal

  $scope.$watch 'selectedVersion', (newVal) ->
    return unless $scope.versions[newVal]?
    return unless navigator.onLine
    updater.update($scope.versions[newVal], $scope.installDir, true)

  $scope.$watch 'updaterProgress.text', (newVal) ->
    if $scope.updaterProgress.inProgress
      $scope.status = newVal

  $scope.$watch 'updaterProgress.inProgress', (newVal) ->
    if !newVal # Not in progress
      updateStatus($scope.selectedVersion)

  $scope.branch = localStorage.getItem('branch') || 'release'
  $scope.installDir = localStorage.getItem('installDir') || paths.gameData
  $scope.serverPort = localStorage.getItem('serverPort') || '4242'

  $scope.update = ->
    electronApp.setPath 'userData', "#{$scope.installDir}/Launcher"
    updater.update($scope.versions[$scope.selectedVersion], $scope.installDir)
