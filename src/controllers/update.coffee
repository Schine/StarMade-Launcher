'use strict'

fs       = require('fs')
os       = require('os')
path     = require('path')
remote   = require('remote')
sanitize = require('sanitize-filename')
archiver = require('archiver')  # compression

dialog      = remote.require('dialog')
electronApp = remote.require('app')

fileExists  = require('../fileexists').fileExists


app = angular.module 'launcher'

app.controller 'UpdateCtrl', ($filter, $rootScope, $scope, $q, $timeout, updater, updaterProgress) ->
  argv = remote.getGlobal('argv')

  $scope.versions = []
  $scope.updaterProgress = updaterProgress
  $scope.status = ''

  $scope.onPlayTab = true
  $scope.onDedicatedTab = false
  $scope.updateHover = false
  $scope.launchHover = false

  $scope.popupData = {}


  strToBool = (str) ->
    return true   if str == "true"
    return false  if str == "false"
    null

  $scope.backupOptions = {}
  # localStorage values are always strings, hence strToBool() for the checkboxes
  $scope.backupOptions.configs         = strToBool localStorage.getItem('backupConfigs')
  $scope.backupOptions.worlds          = strToBool localStorage.getItem('backupWorlds')
  $scope.backupOptions.blueprints      = strToBool localStorage.getItem('backupBlueprints')
  $scope.backupOptions.compressionType =           localStorage.getItem('backupCompressionType')
  # Set Defaults   (as unset values are falsey, || won't work)
  $scope.backupOptions.configs    = true  if $scope.backupOptions.configs    == null
  $scope.backupOptions.worlds     = true  if $scope.backupOptions.worlds     == null
  $scope.backupOptions.blueprints = true  if $scope.backupOptions.blueprints == null
  $scope.backupOptions.blueprints = true  if $scope.backupOptions.blueprints == null
  if $scope.backupOptions.compressionType not in ['zip', 'targz']  # invalid & `null` cases
    if os.platform() == "win32"
      localStorage.setItem('backupCompressionType', 'zip')
      $scope.backupOptions.compressionType = 'zip'
    else
      localStorage.setItem('backupCompressionType', 'targz')
      $scope.backupOptions.compressionType = 'targz'



  $rootScope.log.info "Backup options:",  $rootScope.log.levels.verbose
  $rootScope.log.indent.entry "configs:         #{$scope.backupOptions.configs}",         $rootScope.log.levels.verbose
  $rootScope.log.indent.entry "worlds:          #{$scope.backupOptions.worlds}",          $rootScope.log.levels.verbose
  $rootScope.log.indent.entry "blueprints:      #{$scope.backupOptions.blueprints}",      $rootScope.log.levels.verbose
  $rootScope.log.indent.entry "compressionType: #{$scope.backupOptions.compressionType}", $rootScope.log.levels.verbose



  $scope.backupDialog           = {}
  $scope.backupDialog.error     = {}
  $scope.backupDialog.skipped   = false
  $scope.backupDialog.progress  = {}


  # Save backup options for subsequent sessions
  $scope.$watch 'backupOptions.configs', (newVal) ->
    localStorage.setItem 'backupConfigs', newVal
    $timeout () ->
      $rootScope.log.verbose "set backupConfigs    to #{newVal} (localStorage reread: #{localStorage.getItem('backupConfigs')})"

  $scope.$watch 'backupOptions.worlds', (newVal) ->
    localStorage.setItem 'backupWorlds', newVal
    $timeout () ->
      $rootScope.log.verbose "set backupWorlds     to #{newVal} (localStorage reread: #{localStorage.getItem('backupWorlds')})"

  $scope.$watch 'backupOptions.blueprints', (newVal) ->
    localStorage.setItem 'backupBlueprints', newVal
    $timeout () ->
      $rootScope.log.verbose "set backupBlueprints to #{newVal} (localStorage reread: #{localStorage.getItem('backupBlueprints')})"



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


    $rootScope.log.debug "Sanitizing path"
    $rootScope.log.indent.entry "From: #{$scope.popupData.installDir}",                 $rootScope.log.levels.debug
    $rootScope.log.indent.entry "To:   #{sanitizePath( $scope.popupData.installDir )}", $rootScope.log.levels.debug


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
        $scope.lastUsedVersion       =  version.version.toString()
        $scope.lastUsedVersionHotfix = "#{version.version}#{version.hotfix || ''}"  # used in dialog
        return i.toString()
    return '0'

  $scope.selectLastUsedVersion = ->
    $rootScope.log.verbose "selectLastUsedVersion()"
    $scope.selectedVersion = $scope.getLastUsedVersion()

  updateStatus = (selectedVersion) ->
    return if $scope.versions.length == 0

    $rootScope.log.verbose "updateStatus()"

    if $scope.updaterProgress.needsUpdating
      $scope.status = "You need to update for v#{$scope.versions[selectedVersion].version}#{$scope.versions[selectedVersion].hotfix || ""}"
      $scope.status_updateWarning = "This will overwrite any installed mods."
    else
      $scope.status_updateWarning = ""
      if selectedVersion == '0'
        $scope.status = 'You have the latest version for this build type'
      else
        $scope.status = "You are up-to-date for v#{$scope.versions[selectedVersion].version}#{$scope.versions[selectedVersion].hotfix || ""}"

    if $scope.updaterProgress.indeterminateState
      $scope.status = "Unable to determine installed game version."
      $scope.status_updateWarning = "Update game to resolve."


    if !$scope.starmadeInstalled
      $scope.status = ""
      $scope.status_updateWarning = "Click to install StarMade"

    $rootScope.log.indent.entry "Status:  #{$scope.status}",               $rootScope.log.levels.verbose
    $rootScope.log.indent.entry "Status2: #{$scope.status_updateWarning}", $rootScope.log.levels.verbose



  # Is StarMade is actually installed?
  isStarMadeInstalled = ->
    #TODO: Check for the presence of other files as well.  some files -> not intact; no files -> clean
    $scope.starmadeInstalled = fileExists( path.join($scope.installDir, "StarMade.jar") )
    return $scope.starmadeInstalled

  #TODO: isStarMadeIntact()


  branchChange = (newVal) ->
    $rootScope.log.event "Changing branch to #{newVal.charAt(0).toUpperCase()}#{newVal.slice(1)}"  # Capitalize first character
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
              $scope.updaterProgress.needsUpdating = ($scope.versions[$scope.selectedVersion].build != $scope.lastVersion  ||  !isStarMadeInstalled() || $scope.updaterProgress.indeterminateState)
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
    $scope.popupData.lastVersion = newVal  ##- not used?
    localStorage.setItem 'lastVersion', newVal

  $scope.$watch 'popupData.selectedVersion', (newVal) ->
    $scope.selectedVersion = newVal
    return if not newVal?

    version = $scope.versions[$scope.selectedVersion]
    $rootScope.log.event "Changed selected version to #{version.version}#{version.hotfix || ''}#{if $scope.selectedVersion == '0' then ' (Latest)' else ''}"

  $scope.$watch 'serverPort', (newVal) ->
    localStorage.setItem 'serverPort', newVal

  $scope.$watch 'selectedVersion', (newVal) ->
    $scope.popupData.selectedVersion = newVal
    return unless $scope.versions[newVal]?
    return unless navigator.onLine
    # Require an update when selecting a different version
    $scope.updaterProgress.needsUpdating = ($scope.versions[newVal].build != $scope.lastVersion || !isStarMadeInstalled() || $scope.updaterProgress.indeterminateState)
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


  #TODO: make this public, have it accept a game id
  getInstalledVersion = () ->
    _do_logging = true  if not $rootScope.alreadyExecuted 'log getInstalledVersion'

    if _do_logging
      $rootScope.log.event("Determining installed game version", $rootScope.log.levels.verbose)
      $rootScope.log.indent(1, $rootScope.log.levels.verbose)

    # get current install directory
    dir = localStorage.getItem('installDir')
    if not dir?
      if _do_logging
        $rootScope.log.error("UpdateCtrl: installDir not set")
        $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
      return null

    # Edge-case: version.txt does not exist
    if not fileExists(path.join(dir, "version.txt"))
      # Is it a fresh install?
      if not fileExists(path.join(dir, "StarMade.jar"))
        if _do_logging
          $rootScope.log.info "Fresh install"
          $rootScope.log.indent.debug "Game install path: #{dir}"
          $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
        return null  # unknown version -> suggest updating to latest

      else
        # Otherwise... indeterminable game state with (at least) version.txt missing.
        if _do_logging
          $rootScope.log.error "Unable to determine version of installed game: version.txt missing"
          $rootScope.log.indent.debug "Game install path: #{dir}"
          $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
        # Indeterminable game state requires an update to resolve.
        $scope.updaterProgress.indeterminateState = true
        return null  # unknown version -> suggest updating to latest

    # Parse version.txt  (Expected format: 0.199.132#20160802_134223)
    data = fs.readFileSync(path.join(dir, "version.txt")).toString().trim()  # and strip newline, if present

    # Edge-case: invalid data/format
    if not data.match(/^[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?#[0-9]{8}_[0-9]+$/)?   # backwards-compatibility with previous 0.xxx version numbering
      if _do_logging
        $rootScope.log.error "Unable to determine version of installed game: version.txt contains unexpected data"
        $rootScope.log.indent.debug "Game install path: #{dir}"
        $rootScope.log.indent.debug "Version contents:  #{data}"
        $rootScope.log.outdent(1, $rootScope.log.levels.verbose)
      # Requires an update to resolve.
      $scope.updaterProgress.indeterminateState = true
      return null  # unknown version -> suggest updating to latest

    # Return build data
    [_version, _build] = data.split('#')

    if _do_logging
      $rootScope.log.info "Installed game version: #{_version} (build #{_build})"
      $rootScope.log.outdent(1, $rootScope.log.levels.verbose)

    return _build


  $scope.installDir  = localStorage.getItem('installDir')  # If this isn't set, we have a serious problem.
  $scope.branch      = localStorage.getItem('branch')     || 'release'
  $scope.serverPort  = localStorage.getItem('serverPort') || '4242'
  $scope.lastVersion = getInstalledVersion()               # Installed build id

  if not $scope.installDir?
    $rootScope.log.error("UpdateCtrl: installDir not set")


  # Called by zip/targz radio buttons in index.jade
  $scope.set_zip_compression   = () -> set_backup_compression('zip');
  $scope.set_targz_compression = () -> set_backup_compression('targz');

  set_backup_compression = (newVal) ->
    localStorage.setItem('backupCompressionType', newVal)
    $scope.backupOptions.compressionType = newVal
    $rootScope.log.entry "Changed backup compression type to #{localStorage.getItem('backupCompressionType')}"


  $scope.closeBackupDialog = () ->
    if $scope.backupDialog.visible?
      $rootScope.log.verbose "Closing backup dialog"
    $scope.backupDialog.visible              = null
    $scope.backupDialog.error.visible        = null
    $scope.backupDialog.error.details        = null
    $scope.backupDialog.error.detailsSection = null
    $scope.backupDialog.progress.visible     = null
    $scope.backupDialog.progress.worlds      = null
    $scope.backupDialog.progress.blueprints  = null


  $scope.backup = () ->

    if not ($scope.backupOptions.configs || $scope.backupOptions.worlds || $scope.backupOptions.blueprints)
      $rootScope.log.event "Skipping backup"
      $timeout () ->
        # Show progress with everything as skipped
        $scope.backupDialog.progress.visible    = true
        $scope.backupDialog.progress.configs    = "skipped"
        $scope.backupDialog.progress.worlds     = "skipped"
        $scope.backupDialog.progress.blueprints = "skipped"
        # And mark as complete and show skipped message
        $scope.backupDialog.progress.complete   = true
        $scope.backupDialog.skipped             = true
      return



    $rootScope.log.event "Performing backup (DISABLED FOR DEBUGGING)"
    # $rootScope.log.indent()

    # Show backup progress dialog
    $scope.backupDialog.progress.visible = true


    # try
    #   fs.mkdirSync path.join( path.resolve($scope.installDir), "backups")
    #   $rootScope.log.verbose "Created backups folder"

    # catch err
    #   if err.code != "EEXIST"  # This very likely already exists
    #     # build error description
    #     desc = (err.message || "unknown")
    #     # Log
    #     $rootScope.log.error "Error creating parent backups folder"
    #     $rootScope.log.indent.entry desc
    #     # Show error dialog (using $timeout to wait for the next $digest cycle; it will not show otherwise)
    #     $timeout ->
    #       $scope.backupDialog.error.visible = true
    #       $scope.backupDialog.error.details = desc
    #     # And exit
    #     $rootScope.log.outdent()
    #     return



    # now = new Date
    # # Get date/time portions
    # month   = now.getMonth()+1    # 0-indexed
    # day     = now.getDate()       # 1-indexed
    # hours   = now.getHours()      # 1-indexed
    # minutes = now.getMinutes()    # 1-indexed
    # seconds = now.getSeconds()+1  # 0-indexed
    # # prefix with zeros
    # month   = "0#{month}"    if month   < 10
    # day     = "0#{day}"      if day     < 10
    # hours   = "0#{hours}"    if hours   < 10
    # minutes = "0#{minutes}"  if minutes < 10
    # seconds = "0#{seconds}"  if seconds < 10

    # version = $scope.versions[$scope.selectedVersion]


    # # Format: game/backups/2016-09-06 at 17_08_46 from (0.199.132a) to (0.199.169).tar.gz
    # backupPath  = "#{now.getFullYear()}-#{month}-#{day}"
    # backupPath += " at #{hours}_#{minutes}_#{seconds}"
    # backupPath += " from (#{$scope.lastUsedVersionHotfix})"
    # backupPath += " to (#{version.version}#{version.hotfix || ''})"
    # backupPath += ".zip"     if $scope.backupOptions.compressionType == "zip"
    # backupPath += ".tar.gz"  if $scope.backupOptions.compressionType == "targz"
    # backupPath  = path.resolve( path.join( path.resolve($scope.installDir), "backups", backupPath) )

    # $rootScope.log.verbose "Destination: #{backupPath}"


    # # Create archive stream
    # _format  = "zip"
    # _options = {}

    # if $scope.backupOptions.compressionType == "targz"
    #   _format = "tar"
    #   _options = {
    #     gzip: true,
    #     gzipOptions: {
    #       level: 1
    #     }
    #   }
    # archive            = archiver _format, _options
    # archiveWriteStream = fs.createWriteStream backupPath


    # # Error handlers
    # _error_handler = (err) ->
    #   $rootScope.log.error "Aborted backup. Reason:"
    #   msgs = ["unknown"]
    #   msgs = [err]          if err?
    #   msgs = [err.message]  if err.message?
    #   if typeof err != 'string'  and  Object.keys(err).length > 0
    #     msgs = []
    #     msgs.push "#{key}: #{err[key]}"  for key in Object.keys(err)
    #   $rootScope.log.indent.entry msg  for msg in msgs
    #   $rootScope.log.outdent()

    #   # Display error dialog
    #   $timeout ->
    #     $scope.backupDialog.error.visible         = true
    #     $scope.backupDialog.error.details = msgs.join(". ").trim()
    #   return
    # archive.on            'error', (err) -> _error_handler(err)
    # archiveWriteStream.on 'error', (err) -> _error_handler(err)



    # # Complete handler
    # archive.on 'end', () ->
    #   $rootScope.log.info  "File size: #{archive.pointer()} bytes"
    #   $rootScope.log.entry "Backup complete"
    #   $rootScope.log.outdent()
    #   $timeout () ->
    #     # Show complete dialog
    #     $scope.backupDialog.progress.complete   = true
    #     $scope.backupDialog.path                = backupPath



    # # Show progress page
    # $timeout () ->
    #   $scope.backupDialog.progress.visible = true


    # # Add configs
    # if $scope.backupOptions.configs
    #   $timeout () -> $scope.backupDialog.progress.configs = true
    #   configs = ["settings.cfg", "server.cfg", "keyboard.cfg", "joystick.cfg"]
    #   _found = false
    #   for config in configs
    #     # Skip configs that do not exist, e.g. "joystick.cfg"
    #     continue  if not fileExists path.resolve( path.join($scope.installDir, config) )
    #     _found = true
    #     archive.file(
    #       path.resolve(path.join($scope.installDir, config)),
    #       {name: config}
    #     )
    #   if not _found
    #     $timeout () -> $scope.backupDialog.progress.configs = "missing"
    # else
    #   $timeout () ->  $scope.backupDialog.progress.configs = "skipped"


    # # Add worlds
    # if $scope.backupOptions.worlds
    #   $timeout () -> $scope.backupDialog.progress.worlds = true
    #   if fileExists path.resolve( path.join($scope.installDir, "server-database") )
    #     archive.directory(
    #       path.resolve(path.join($scope.installDir, "server-database")),
    #       "server-database"
    #     )
    #   else $scope.backupDialog.progress.worlds = "missing"
    # else $scope.backupDialog.progress.worlds = "skipped"


    # # Add blueprints
    # if $scope.backupOptions.blueprints
    #   $timeout () -> $scope.backupDialog.progress.blueprints = true
    #   if fileExists path.resolve( path.join($scope.installDir, "blueprints") )
    #     archive.directory(
    #       path.resolve(path.join($scope.installDir, "blueprints")),
    #       "blueprints"
    #     )
    #   else $scope.backupDialog.progress.blueprints = "missing"
    # else $scope.backupDialog.progress.blueprints = "skipped"


    # # Finalize
    # archive.finalize()
    # archive.pipe(archiveWriteStream)
    return





  $scope.pre_update = (force = false) ->
    # Skip if --nobackup
    if $rootScope.noBackup
      $rootScope.log.info "Bypassing backup"
      return $scope.update(force)

    # Ensure game directory exists
    if not fileExists(path.resolve($scope.installDir))
      $rootScope.log.info "Skipping backup: fresh install"
      return $scope.update(force)

    # Ensure at least one of [blueprints, server-database] exist
    blueprints = fileExists path.resolve( path.join($scope.installDir, "blueprints") )
    database   = fileExists path.resolve( path.join($scope.installDir, "server-database") )

    if blueprints or database
      if $scope.backupDialog.visible == true
        # Don't log if already visible.
        return

      # Show backup dialog
      $rootScope.log.event "Presenting backup dialog"
      $scope.update_force = force  # preserve `force` param
      $scope.backupDialog.visible = true
    else
      # Otherwise, continue with the update
      $rootScope.log.info "Backup"
      $rootScope.log.indent.entry "Neither blueprints nor worlds folders exist"
      $rootScope.log.indent.entry "Aborting backup and continuing with udpdate"
      $scope.update()


  $scope.update = (force = false) ->
    $scope.closeBackupDialog()

    # Supplied `force` param overrides saved param from `pre_update()`
    force = force || $scope.update_force
    $scope.update_force = null

    version = $scope.versions[$scope.selectedVersion]
    $rootScope.log.verbose "Target version: #{JSON.stringify(version)}"
    $scope.lastVersion = version.build

    $rootScope.log.event "Updating game from #{$scope.lastUsedVersionHotfix} to #{version.version}#{version.hotfix || ''}#{if $scope.selectedVersion == '0' then ' (Latest)' else ''}"

    $scope.getLastUsedVersion()  # update displayed 'Currently Installed' version
    $scope.status_updateWarning = ""
    $scope.starmadeInstalled = true
    $scope.updaterProgress.indeterminateState = false
    updater.update(version, $scope.installDir, false, force)
