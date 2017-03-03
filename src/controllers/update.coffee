'use strict'

fs       = require('fs')
os       = require('os')
path     = require('path')
remote   = require('remote')
archiver = require('archiver')  # compression

dialog      = remote.require('dialog')
electronApp = remote.require('app')

fileExists  = require('../fileexists').fileExists


app = angular.module 'launcher'


# Catch unhandled errors
angular.module('app', []).config ($provide) ->
  $provide.decorator "$exceptionHandler", ($delegate, $injector) ->
    (exception, cause) ->
      $rootScope = $injector.get("$rootScope");

      $rootScope.log.error "Uncaught Error"
      $rootScope.log.indent.debug "exception: #{exception}"
      $rootScope.log.indent.debug "cause:     #{cause}"

      msgs = ["unknown"]
      msgs = [exception]          if exception?
      msgs = [exception.message]  if exception.message?
      if typeof exception != 'string'  and  Object.keys(exception).length > 0
        msgs = []
        msgs.push "#{key}: #{exception[key]}"  for key in Object.keys(exception)
      $rootScope.log.indent.entry msg  for msg in msgs
      $rootScope.log.outdent()

      $delegate(exception, cause);




app.controller 'UpdateCtrl', ($filter, $rootScope, $scope, $q, $timeout, updater, updaterProgress, settings) ->
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
      $rootScope.log.verbose "Set backupConfigs    to #{newVal} (localStorage reread: #{localStorage.getItem('backupConfigs')})"

  $scope.$watch 'backupOptions.worlds', (newVal) ->
    localStorage.setItem 'backupWorlds', newVal
    $timeout () ->
      $rootScope.log.verbose "Set backupWorlds     to #{newVal} (localStorage reread: #{localStorage.getItem('backupWorlds')})"

  $scope.$watch 'backupOptions.blueprints', (newVal) ->
    localStorage.setItem 'backupBlueprints', newVal
    $timeout () ->
      $rootScope.log.verbose "Set backupBlueprints to #{newVal} (localStorage reread: #{localStorage.getItem('backupBlueprints')})"



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

  #TODO: remove
  $scope.openOptions = (name) ->
    switch name
      when 'buildType'
        $scope.buildTypeOptions = true
        $scope.popupData.branch = $scope.branch
        $scope.popupData.installDir = path.resolve( $scope.install.path )
      when 'buildVersion'
        $scope.buildVersionOptions = true

  $scope.closeOptions = (name) ->
    switch name
      when 'buildType'
        $scope.buildTypeOptions = false
      when 'buildVersion'
        $scope.buildVersionOptions = false




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
    $rootScope.log.info "Checking for StarMade install"
    unless $scope.install.path?
      $rootScope.log.indent.error "Install path not set!"
      return null

    #TODO: Check for the presence of other files as well.  some files -> not intact; no files -> clean
    $scope.starmadeInstalled = fileExists( path.join($scope.install.path, "StarMade.jar") )

    $rootScope.log.indent.entry "Path:  #{path.join($scope.install.path, 'StarMade.jar')}",  $rootScope.log.levels.verbose

    if $scope.starmadeInstalled
      $rootScope.log.indent.entry "Installed"
    else
      $rootScope.log.indent.entry "Not Installed"
    return $scope.starmadeInstalled

  #TODO: isStarMadeIntact()


  branchChange = (newVal) ->
    unless validBranch(newVal)
      $rootScope.log.error "Trying to change to an invalid branch (#{newVal})"
      return

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

              updater.update($scope.versions[$scope.selectedVersion], $scope.install.path, false)

              $scope.$watch 'updaterProgress.inProgress', (newVal) ->
                # Quit when done
                electronApp.quit() if !newVal
            else
              # Update only when selecting a different build version
              $scope.updaterProgress.needsUpdating = ($scope.versions[$scope.selectedVersion].build != $scope.lastVersion  ||  !isStarMadeInstalled() || $scope.updaterProgress.indeterminateState)
              # updater.update($scope.versions[$scope.selectedVersion], $scope.install.path, true)
      , ->
        $scope.status = 'You are offline.' unless navigator.onLine
        $scope.switchingBranch = false
        $scope.versions = []
        $scope.selectedVersion = null

  $scope.selectNewestVersion = () ->
    $scope.popupData.selectedVersion = '0'  # selects the first item

  $rootScope.$watch 'launcherUpdating', (updating) ->
    branchChange($scope.branch) unless updating


  validBranch = (branch) ->
    branch in ['pre', 'dev', 'release', 'archive', 'launcher']

  $scope.$watch 'branch', (newVal) ->
    return if     $rootScope.launcherUpdating
    return unless newVal?  # likely just not set yet

    unless validBranch(newVal)
      $rootScope.log.error "Invalid branch set (#{newVal})"
      $rootScope.log.indent.entry "Reverting to 'release'"
      $scope.branch = newVal = 'release'

    $rootScope.log.verbose "Branch set to: #{newVal}"
    localStorage.setItem 'branch', newVal
    branchChange(newVal)

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

  #TODO: Move to settings
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


  # return {version, build, branch}
  getInstalledVersion = (installpath) ->
    $rootScope.log.event "Determining installed game version"
    $rootScope.log.indent()

    # This should not happen
    unless installpath?
      $rootScope.log.error "Invalid install path (#{installpath})"
      $rootScope.log.outdent()

      # (Cannot determine)
      return game =
               version: undefined
               build:   undefined
               branch:  undefined


    $rootScope.log.indent.debug "path:  #{installpath}"


    # Edge-case: version.txt does not exist
    unless fileExists(path.join(installpath, "version.txt"))
      # Is it a fresh install?
      unless fileExists(path.join(installpath, "StarMade.jar"))
        $rootScope.log.info "Fresh install"
        $rootScope.log.outdent()

        # (No game installed)
        return game =
                 version: null
                 build:   null
                 branch:  null

      else
        # Otherwise... indeterminable game state with (at least) version.txt missing.
        $rootScope.log.error "Unable to determine version of installed game: version.txt missing"
        $rootScope.log.outdent()
        # Indeterminable game state requires an update to resolve.
        $scope.updaterProgress.indeterminateState = true

        # (Cannot determine)
        return game =
                 version: undefined
                 build:   undefined
                 branch:  undefined


    # Parse version.txt  (Expected format: 0.199.132#20160802_134223)
    data = fs.readFileSync(path.join(installpath, "version.txt")).toString().trim()  # and strip newline, if present

    # Edge-case: invalid data/format
    unless data.match(/^[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?#[0-9]{8}_[0-9]+$/)?   # backwards-compatibility with previous 0.xxx version numbering
      $rootScope.log.error "Unable to determine version of installed game: version.txt contains unexpected data"
      $rootScope.log.indent.entry "contents:  #{data}"
      $rootScope.log.outdent()
      # Requires an update to resolve.
      $scope.updaterProgress.indeterminateState = true

      # (Cannot determine)
      return game =
                 version: undefined
                 build:   undefined
                 branch:  undefined

    # Return build data
    [_version, _build] = data.split('#')

    $rootScope.log.info "Installed game:"
    $rootScope.log.indent.entry "version: #{_version}"
    $rootScope.log.indent.entry "build:   #{_build}"
    $rootScope.log.outdent()

    return game =
             version: _version
             build:   _build
             branch:  undefined


  settings.ready.then ->
    $rootScope.log.important "Update: Settings initialized"
    $scope.install     = settings.install  # If `install.path` isn't set, we have a serious problem.
    $scope.branch      = localStorage.getItem('branch')     || 'release'  #TODO determine this from the build, preferring release
    $scope.serverPort  = localStorage.getItem('serverPort') || '4242'

    if not $scope.install.path?
      $rootScope.log.error "Install path not set!"
      $rootScope.log.indent.entry "from settings:  #{settings.install.path}"


  # On install directory change, parse the new version.txt and update accordingly
  $scope.$watch 'install.path', (newVal) ->
    return  unless newVal?
    game = getInstalledVersion(newVal)
    #TODO handle `undefined` (unknown build) and `null` (not installed) values
    #TODO determine branch from build id, preferring 'release' over 'dev'
    $scope.lastVersion = game.build

    ## Do we still want this?
    # if $scope.branch == $scope.panes.install.branch && $scope.path != $scope.panes.install.path
    #   # Scan the new install directroy
    #   $scope.status_updateWarning = ""  # Remove the warning, if present
    #   ##TODO make this actually read the installed version from the new directory
    #   updater.update($scope.versions[$scope.selectedVersion], $scope.panes.install.path, true)




  # Called by zip/targz radio buttons in index.jade
  $scope.set_zip_compression   = () -> set_backup_compression('zip');
  $scope.set_targz_compression = () -> set_backup_compression('targz');

  set_backup_compression = (newVal) ->
    return  if localStorage.getItem('backupCompressionType') == newVal
    localStorage.setItem('backupCompressionType', newVal)
    $scope.backupOptions.compressionType = newVal
    $rootScope.log.entry "Set backup compression type to #{localStorage.getItem('backupCompressionType')}"


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



    $rootScope.log.event "Performing backup"
    $rootScope.log.indent()

    # Show backup progress dialog
    $scope.backupDialog.progress.visible = true


    try
      fs.mkdirSync path.join( path.resolve($scope.install.path), "backups")
      $rootScope.log.verbose "Created backups folder"

    catch err
      if err.code != "EEXIST"  # This very likely already exists
        # build error description
        desc = (err.message || "unknown")
        # Log
        $rootScope.log.error "Error creating parent backups folder"
        $rootScope.log.indent.entry desc
        # Show error dialog (using $timeout to wait for the next $digest cycle; it will not show otherwise)
        $timeout ->
          $scope.backupDialog.error.visible = true
          $scope.backupDialog.error.details = desc
        # And exit
        $rootScope.log.outdent()
        return



    now = new Date
    # Get date/time portions
    month   = now.getMonth()+1    # 0-indexed
    day     = now.getDate()       # 1-indexed
    hours   = now.getHours()      # 1-indexed
    minutes = now.getMinutes()    # 1-indexed
    seconds = now.getSeconds()+1  # 0-indexed
    # prefix with zeros
    month   = "0#{month}"    if month   < 10
    day     = "0#{day}"      if day     < 10
    hours   = "0#{hours}"    if hours   < 10
    minutes = "0#{minutes}"  if minutes < 10
    seconds = "0#{seconds}"  if seconds < 10

    version = $scope.versions[$scope.selectedVersion]


    # Format: game/backups/2016-09-06 at 17_08_46 from (0.199.132a) to (0.199.169).tar.gz
    backupPath  = "#{now.getFullYear()}-#{month}-#{day}"
    backupPath += " at #{hours}_#{minutes}_#{seconds}"
    backupPath += " from (#{$scope.lastUsedVersionHotfix})"
    backupPath += " to (#{version.version}#{version.hotfix || ''})"
    backupPath += ".zip"     if $scope.backupOptions.compressionType == "zip"
    backupPath += ".tar.gz"  if $scope.backupOptions.compressionType == "targz"
    backupPath  = path.resolve( path.join( path.resolve($scope.install.path), "backups", backupPath) )

    $rootScope.log.verbose "Destination: #{backupPath}"


    # Create archive stream
    _format  = "zip"
    _options = {}

    if $scope.backupOptions.compressionType == "targz"
      _format = "tar"
      _options = {
        gzip: true,
        gzipOptions: {
          level: 1
        }
      }
    archive            = archiver _format, _options
    archiveWriteStream = fs.createWriteStream backupPath


    # Error handlers
    _error_handler = (err) ->
      $rootScope.log.error "Aborted backup. Reason:"
      msgs = ["unknown"]
      msgs = [err]          if err?
      msgs = [err.message]  if err.message?
      if typeof err != 'string'  and  Object.keys(err).length > 0
        msgs = []
        msgs.push "#{key}: #{err[key]}"  for key in Object.keys(err)
      $rootScope.log.indent.entry msg  for msg in msgs
      $rootScope.log.outdent()

      # Display error dialog
      $timeout ->
        $scope.backupDialog.error.visible         = true
        $scope.backupDialog.error.details = msgs.join(". ").trim()
      return
    archive.on            'error', (err) -> _error_handler(err)
    archiveWriteStream.on 'error', (err) -> _error_handler(err)



    # Complete handler
    archive.on 'end', () ->
      $rootScope.log.info  "File size: #{archive.pointer()} bytes"
      $rootScope.log.entry "Backup complete"
      $rootScope.log.outdent()
      $timeout () ->
        # Show complete dialog
        $scope.backupDialog.progress.complete   = true
        $scope.backupDialog.path                = backupPath



    # Show progress page
    $timeout () ->
      $scope.backupDialog.progress.visible = true


    # Add configs
    if $scope.backupOptions.configs
      $timeout () -> $scope.backupDialog.progress.configs = true
      configs = ["settings.cfg", "server.cfg", "keyboard.cfg", "joystick.cfg"]
      _found = false
      for config in configs
        # Skip configs that do not exist, e.g. "joystick.cfg"
        continue  if not fileExists path.resolve( path.join($scope.install.path, config) )
        _found = true
        archive.file(
          path.resolve(path.join($scope.install.path, config)),
          {name: config}
        )
      if not _found
        $timeout () -> $scope.backupDialog.progress.configs = "missing"
    else
      $timeout () ->  $scope.backupDialog.progress.configs = "skipped"


    # Add worlds
    if $scope.backupOptions.worlds
      $timeout () -> $scope.backupDialog.progress.worlds = true
      if fileExists path.resolve( path.join($scope.install.path, "server-database") )
        archive.directory(
          path.resolve(path.join($scope.install.path, "server-database")),
          "server-database"
        )
      else $scope.backupDialog.progress.worlds = "missing"
    else $scope.backupDialog.progress.worlds = "skipped"


    # Add blueprints
    if $scope.backupOptions.blueprints
      $timeout () -> $scope.backupDialog.progress.blueprints = true
      if fileExists path.resolve( path.join($scope.install.path, "blueprints") )
        archive.directory(
          path.resolve(path.join($scope.install.path, "blueprints")),
          "blueprints"
        )
      else $scope.backupDialog.progress.blueprints = "missing"
    else $scope.backupDialog.progress.blueprints = "skipped"


    # Finalize
    archive.finalize()
    archive.pipe(archiveWriteStream)
    return





  $scope.pre_update = (force = false) ->
    # Skip if --nobackup
    if $rootScope.noBackup
      $rootScope.log.info "Bypassing backup"
      return $scope.update(force)

    # Ensure game directory exists
    if not fileExists(path.resolve($scope.install.path))
      $rootScope.log.info "Skipping backup: fresh install"
      return $scope.update(force)

    # Ensure at least one of [blueprints, server-database] exist
    blueprints = fileExists path.resolve( path.join($scope.install.path, "blueprints") )
    database   = fileExists path.resolve( path.join($scope.install.path, "server-database") )

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
    updater.update(version, $scope.install.path, false, force)
