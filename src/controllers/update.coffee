'use strict'

angular = require('angular')
del = require('del')
remote = require('remote')

dialog = remote.require('dialog')

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

  $scope.popupData = {}

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

  $scope.openOptions = (name) ->
    switch name
      when 'buildType'
        $scope.buildTypeOptions = true
        $scope.popupData.branch = $scope.branch
        $scope.popupData.installDir = $scope.installDir
      when 'buildVersion'
        $scope.buildVersionOptions = true

  $scope.closeOptions = (name) ->
    switch name
      when 'buildType'
        $scope.buildTypeOptions = false
      when 'buildVersion'
        $scope.buildVersionOptions = false


  $scope.browseInstallDir = ->
    dialog.showOpenDialog remote.getCurrentWindow(),
      title: 'Select Installation Directory'
      properties: ['openDirectory']
    , (path) ->
      return unless path?
      $scope.popupData.installDir = path

  $scope.popupBuildTypeSave = ->
    $scope.branch = $scope.popupData.branch
    $scope.installDir = $scope.popupData.installDir
    $scope.buildTypeOptions = false

  $scope.selectLastUsedVersion = ->
    for version, i in $scope.versions
      if version.build == $scope.lastVersion
        $scope.selectedVersion = i
        return

    $scope.selectedVersion = 0

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

        # Workaround for when ngRepeat hasn't processed the versions yet
        requestAnimationFrame ->
          $scope.$apply ->
            if $scope.lastVersion?
              $scope.selectLastUsedVersion()
            else
              $scope.lastVersion = $scope.versions[0].build
              $scope.selectedVersion = 0

            updater.update($scope.versions[$scope.selectedVersion], $scope.installDir, true)
      , ->
        $scope.status = 'You are offline.' unless navigator.onLine
        $scope.switchingBranch = false
        $scope.versions = []
        $scope.selectedVersion = null

  $scope.$watch 'installDir', (newVal) ->
    localStorage.setItem 'installDir', newVal

  $scope.$watch 'lastVersion', (newVal) ->
    return unless newVal?
    $scope.popupData.lastVersion = newVal
    localStorage.setItem 'lastVersion', newVal

  $scope.$watch 'popupData.selectedVersion', (newVal) ->
    $scope.selectedVersion = newVal

  $scope.$watch 'serverPort', (newVal) ->
    localStorage.setItem 'serverPort', newVal

  $scope.$watch 'selectedVersion', (newVal) ->
    $scope.popupData.selectedVersion = newVal
    return unless $scope.versions[newVal]?
    return unless navigator.onLine
    updater.update($scope.versions[newVal], $scope.installDir, true)

  $scope.$watch 'updaterProgress.text', (newVal) ->
    if $scope.updaterProgress.inProgress
      $scope.status = newVal

  $scope.$watch 'updaterProgress.inProgress', (newVal) ->
    if !newVal # Not in progress
      updateStatus($scope.selectedVersion)

  $scope.lastVersion = localStorage.getItem('lastVersion')
  $scope.branch = localStorage.getItem('branch') || 'release'
  $scope.installDir = localStorage.getItem('installDir') || paths.gameData
  $scope.serverPort = localStorage.getItem('serverPort') || '4242'

  $scope.forceUpdate = ->
    $scope.popupData.deleting = true
    del ["#{$scope.installDir}/*", "!#{$scope.installDir}/Launcher"], {force: true}, (err) ->
      $scope.popupData.deleting = false
      if err
        console.error err
        return

      $scope.update()

  $scope.update = ->
    electronApp.setPath 'userData', "#{$scope.installDir}/Launcher"
    version = $scope.versions[$scope.selectedVersion]
    $scope.lastVersion = version.build
    updater.update(version, $scope.installDir)
