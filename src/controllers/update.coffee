'use strict'

remote = require('remote')

dialog = remote.require('dialog')

electronApp = remote.require('app')

app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($filter, $rootScope, $scope, updater, updaterProgress) ->
  argv = remote.getGlobal('argv')

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
      $scope.popupData.installDir = path[0]

  $scope.popupBuildTypeSave = ->
    if $scope.branch == $scope.popupData.branch && $scope.installDir != $scope.popupData.installDir
      # Scan the new install directroy
      updater.update($scope.versions[$scope.selectedVersion], $scope.popupData.installDir, true)

    $scope.branch = $scope.popupData.branch
    $scope.installDir = $scope.popupData.installDir
    $scope.buildTypeOptions = false

  $scope.selectLastUsedVersion = ->
    for version, i in $scope.versions
      if version.build == $scope.lastVersion
        $scope.selectedVersion = i.toString()
        return

    $scope.selectedVersion = '0'

  updateStatus = (selectedVersion) ->
    return if $scope.versions.length == 0

    if $scope.updaterProgress.needsUpdating
      $scope.status = "You need to update for v#{$scope.versions[selectedVersion].version}"
      $scope.status_updateWarning = "This will overwrite any installed mods."
    else
      $scope.status_updateWarning = ""
      if selectedVersion == '0'
        $scope.status = 'You have the latest version for this Build Type'
      else
        $scope.status = "You are up-to-date for v#{$scope.versions[selectedVersion].version}"

  branchChange = (newVal) ->
    $scope.switchingBranch = true
    updater.getVersions newVal
      .then (versions) ->
        $scope.switchingBranch = false
        $scope.versions = $filter('orderBy')(versions, '-build')
        $scope.versions[0].latest = '(Latest)'

        # Workaround for when ngRepeat hasn't processed the versions yet
        requestAnimationFrame ->
          $scope.$apply ($scope) ->
            if $scope.lastVersion?
              $scope.selectLastUsedVersion()
            else
              $scope.lastVersion = $scope.versions[0].build
              $scope.selectedVersion = '0'

            if $rootScope.nogui
              # Always use the latest version with -nogui
              $scope.lastVersion = $scope.versions[0].build
              $scope.selectedVersion = '0'

              updater.update($scope.versions[$scope.selectedVersion], $scope.installDir, false)

              $scope.$watch 'updaterProgress.inProgress', (newVal) ->
                # Quit when done
                electronApp.quit() if !newVal
            else
              # Update only when selecting a different build version
              $scope.updaterProgress.needsUpdating = ($scope.versions[$scope.selectedVersion].build != $scope.lastVersion)
              # updater.update($scope.versions[$scope.selectedVersion], $scope.installDir, true)
      , ->
        $scope.status = 'You are offline.' unless navigator.onLine
        $scope.switchingBranch = false
        $scope.versions = []
        $scope.selectedVersion = null

  $rootScope.$watch 'launcherUpdating', (updating) ->
    branchChange($scope.branch) unless updating

  $scope.$watch 'branch', (newVal) ->  ##
    return if $rootScope.launcherUpdating
    localStorage.setItem 'branch', newVal
    branchChange(newVal)

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
    # Require an update when selecting a different version
    $scope.updaterProgress.needsUpdating = ($scope.versions[newVal].build != $scope.lastVersion)
    updateStatus(newVal)

  $scope.$watch 'updaterProgress.text', (newVal) ->
    if $scope.updaterProgress.inProgress
      $scope.status = newVal

  $scope.$watch 'updaterProgress.inProgress', (newVal) ->
    if !newVal # Not in progress
      updateStatus($scope.selectedVersion)

  # Override settings with supplied arguments
  if argv['install-dir']?
    localStorage.setItem('installDir', argv['install-dir'])

  if argv.archive
    localStorage.setItem('branch', 'archive')

  if argv.dev
    localStorage.setItem('branch', 'dev')

  if argv.latest
    localStorage.removeItem('lastVersion')

  if argv.pre
    localStorage.setItem('branch', 'pre')

  if argv.release
    localStorage.setItem('branch', 'release')

  $scope.lastVersion = localStorage.getItem('lastVersion')
  $scope.branch = localStorage.getItem('branch') || 'release'
  $scope.installDir = localStorage.getItem('installDir') || path.resolve(path.join(electronApp.getPath('userData'), '..'))
  $scope.serverPort = localStorage.getItem('serverPort') || '4242'

  $scope.update = (force = false) ->
    version = $scope.versions[$scope.selectedVersion]
    $scope.lastVersion = version.build
    updater.update(version, $scope.installDir, false, force)
