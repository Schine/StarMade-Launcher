'use strict'

fs       = require('fs')
os       = require('os')
path     = require('path')
remote   = require('remote')
sanitize = require('sanitize-filename')

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
        $scope.popupData.installDir = path.resolve( $scope.installDir )
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
    , (newPath) ->
      return unless newPath?
      newPath = path.resolve(newPath[0])

      # Scenario: existing install
      if fs.existsSync( path.join(newPath, "StarMade.jar") )
        # console.log "installBrowse(): Found StarMade.jar here:  #{path.join(newPath, "StarMade.jar")}"
        $scope.popupData.installDir = newPath
        return

      # Scenario: StarMade/StarMade
      if (path.basename(             newPath.toLowerCase())  == "starmade" &&
          path.basename(path.dirname(newPath.toLowerCase())) == "starmade" )  # ridiculous, but functional
        # console.log "installBrowse(): Path ends in StarMade/StarMade  (path: #{newPath})"
        $scope.popupData.installDir = newPath
        return

      # Default: append StarMade
      $scope.popupData.installDir = path.join(newPath, 'StarMade')


  $scope.popupBuildTypeSave = ->
    if $scope.popupData.installDir.trim() == ""
      $scope.popupData.installDir_error = "Install path cannot be blank."
      return

    $scope.popupData.installDir_error = ""

    if $scope.branch == $scope.popupData.branch && $scope.installDir != $scope.popupData.installDir
      # Scan the new install directroy
      $scope.status_updateWarning = ""  # Remove the warning, if present
      ##TODO make this actually read the installed version from the new directory
      updater.update($scope.versions[$scope.selectedVersion], sanitizePath($scope.popupData.installDir), true)


    if $rootScope.verbose
      console.log "------Sanitizing path------"
      console.log " | From: #{$scope.popupData.installDir}"
      console.log " | To:   #{sanitizePath( $scope.popupData.installDir )}"
      console.log "------      End      ------"


    $scope.branch           = $scope.popupData.branch
    $scope.installDir       = sanitizePath( $scope.popupData.installDir )
    $scope.buildTypeOptions = false


  # Cross-platform path sanitizing
  # Relies on the `sanitize-filename` npm package
  ##! Possible issues:
  #     * (Win32)  A malformed drive letter causes the malformed path to be treated as relative to the current directory.  This is due to the initial `path.resolve()`
  sanitizePath = (str) ->
    # Resolve into an absolute path first
    str = path.resolve(str)
    # and split the resulting path into tokens
    tokens = str.split(path.sep)

    # For Win32, retain the root drive
    root = null
    if os.platform() == "win32"
      root = tokens.shift()
      # Sanitize it, and add the ":" back
      root = sanitize(root) + ":"

    # Sanitize each token in turn
    for token, index in tokens
      tokens[index] = sanitize(token)

    # Remove all empty elements
    tokens.filter (n) ->
      n != ""

    # Rebuild array
    new_path = tokens.join( path.sep )

    # Restore the root of the path
    if os.platform() == "win32"
      new_path = path.join(root, new_path)  # Win32: drive letter
    else
      new_path = path.sep + new_path        # POSIX: leading /

    # And return our new, sparkling-clean path
    new_path



  $scope.getLastUsedVersion = ->
    for version, i in $scope.versions
      if version.build == $scope.lastVersion
        $scope.lastUsedVersion = version.version.toString()
        return i.toString()
    return '0'

  $scope.selectLastUsedVersion = ->
    $scope.selectedVersion = $scope.getLastUsedVersion()

  updateStatus = (selectedVersion) ->
    return if $scope.versions.length == 0

    if $scope.updaterProgress.needsUpdating
      $scope.status = "You need to update for v#{$scope.versions[selectedVersion].version}#{$scope.versions[selectedVersion].hotfix || ""}"
      $scope.status_updateWarning = "This will overwrite any installed mods."
    else
      $scope.status_updateWarning = ""
      if selectedVersion == '0'
        $scope.status = 'You have the latest version for this build type'
      else
        $scope.status = "You are up-to-date for v#{$scope.versions[selectedVersion].version}#{$scope.versions[selectedVersion].hotfix || ""}"

    if !$scope.starmadeInstalled
      $scope.status = "StarMade.jar missing; click to repair."
      $scope.status_updateWarning = "This will overwrite any installed mods."




  # Starmade Jar path
  starmadeJarPath = ->
    path.resolve "#{$scope.installDir}/StarMade.jar"

  # check if StarMade is actually installed
  bIsStarmadeInstalled = ->
    try
      # since Node changes the fs.exists() functions with every version
      fs.closeSync( fs.openSync(starmadeJarPath(), "r") )
      return $scope.starmadeInstalled = true
    catch e
      return $scope.starmadeInstalled = false


  branchChange = (newVal) ->
    $scope.switchingBranch = true
    updater.getVersions newVal
      .then (versions) ->
        $scope.switchingBranch = false
        $scope.versions = $filter('orderBy')(versions, '-build')

        # Add hotfix indicators to duplicate version entries
        index            = $scope.versions.length - 1
        previous_version = null
        hotfix_counter   = 0

        # Work backwards through the list
        while index >= 0
          if index-1 >= 0  # all but the last entry
            if $scope.versions[index].version == previous_version
              # and add hotfix indicators to the second, third, etc. matching entries
              $scope.versions[index].hotfix = String.fromCharCode(97 + hotfix_counter++)
              ##! This will cause problems in the unlikely event there are >26 hotfixes for the same version
            else
              previous_version = $scope.versions[index].version
              hotfix_counter   = 0
          else  # last entry
            if $scope.versions[index].version == previous_version
              $scope.versions[index].hotfix = String.fromCharCode(97 + hotfix_counter++)
          index--
        # end hotfix indicators


        # Add Latest indicator
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
              $scope.updaterProgress.needsUpdating = ($scope.versions[$scope.selectedVersion].build != $scope.lastVersion  ||  !bIsStarmadeInstalled())
              # updater.update($scope.versions[$scope.selectedVersion], $scope.installDir, true)
      , ->
        $scope.status = 'You are offline.' unless navigator.onLine
        $scope.switchingBranch = false
        $scope.versions = []
        $scope.selectedVersion = null

  $scope.selectNewestVersion = () ->
    $scope.popupData.selectedVersion = '0'  # selects the first item

  $rootScope.$watch 'launcherUpdating', (updating) ->
    branchChange($scope.branch) unless updating

  $scope.$watch 'branch', (newVal) ->
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
    $scope.updaterProgress.needsUpdating = ($scope.versions[newVal].build != $scope.lastVersion || !bIsStarmadeInstalled())
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
    $scope.getLastUsedVersion()  # update displayed 'Currently Installed' version
    $scope.status_updateWarning = ""
    $scope.starmadeInstalled = true
    updater.update(version, $scope.installDir, false, force)
