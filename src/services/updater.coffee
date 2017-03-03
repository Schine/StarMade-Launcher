'use strict'

_          = require('underscore')
fs         = require('original-fs')
ipc        = require('ipc')
path       = require('path')
async      = require('async')
request    = require('request')
fileExists = require('../fileexists').fileExists


app = angular.module 'launcher'

app.service 'updater', ($q, $http, Checksum, Version, $rootScope, updaterProgress) ->
  BASE_URL = 'http://files.star-made.org'
  LAUNCHER_BASE_URL = 'http://launcher-files-origin.star-made.org'
  BRANCH_INDEXES =
    pre:      "#{BASE_URL}/prebuildindex"
    dev:      "#{BASE_URL}/devbuildindex"
    release:  "#{BASE_URL}/releasebuildindex"
    archive:  "#{BASE_URL}/archivebuildindex"
    launcher: "#{LAUNCHER_BASE_URL}/launcherbuildindex"


  @update = (version, installDir, checkOnly = false, force = false) ->
    return if updaterProgress.inProgress

    $rootScope.log.event "Updating game..."

    $rootScope.log.indent.info "(checkOnly)"  if checkOnly
    $rootScope.log.indent.info "(forced)"     if force


    updaterProgress.curValue = 0
    updaterProgress.inProgress = true
    updaterProgress.text = 'Getting checksums'
    $rootScope.log.entry "Getting checksums"

    @getChecksums(version.path)
      .then (checksums) ->
        filesToDownload = []

        download = _.after checksums.length, ->
          if filesToDownload.length == 0
            updaterProgress.text = 'Up to date'
            updaterProgress.needsUpdating = false
            updaterProgress.inProgress = false
            $rootScope.log.info "Up to date"
            return

          downloadSize = 0
          filesToDownload.forEach (checksum) ->
            downloadSize += checksum.size

          updaterProgress.curValue = 0
          updaterProgress.maxValue = downloadSize
          updaterProgress.filesCount = filesToDownload.length
          updaterProgress.updateText()

          q = async.queue (checksum, callback) ->
            checksum.download installDir
              .then ->
                callback null
              , (err) ->
                callback err
          , 5

          q.drain = ->
            updaterProgress.text = 'All files downloaded'
            updaterProgress.inProgress = false
            updaterProgress.needsUpdating = false
            $rootScope.log.info "All files downloaded"

          if checkOnly
            updaterProgress.needsUpdating = true
            updaterProgress.inProgress = false
          else
            filesToDownload.forEach (checksum) ->
              q.push checksum, (err) ->
                $rootScope.log.error err if err

        updaterProgress.text = 'Determining files to download...'
        updaterProgress.curValue = 0
        updaterProgress.maxValue = checksums.length

        totalSize = 0
        checksums.forEach (checksum) ->
          totalSize += checksum.size

        checksums.forEach (checksum) ->
          checksum.checkLocal installDir
            .then (needsDownloading) ->
              filesToDownload.push(checksum) if needsDownloading || force
              updaterProgress.text = "Determining files to download... #{updaterProgress.calculatePercentage()}%  selected #{filesToDownload.length}/#{checksums.length} (#{updaterProgress.toMegabytes(totalSize)} MB)"
              updaterProgress.curValue++
              download()

  @updateLauncher = (version, launcherDir) ->
    resourcesDir = null
    if process.platform == 'darwin'
      resourcesDir = path.join launcherDir, '..', 'Resources'
    else
      resourcesDir = path.join launcherDir, 'resources'

    return new Promise (resolve, reject) ->
      $rootScope.log.update "Updating launcher to v#{version.version}"
      fetchUpdate(version, resourcesDir)
        .then () -> applyUpdate(resourcesDir)
        .then () -> cleanupUpdate(resourcesDir)
        .then () -> resolve()
      .catch (err) ->
        reject(err)




  fetchUpdate = (version, dir) ->
    fetch_failed = false  # Hack; see below.

    return new Promise (resolve, reject) ->
      # cloud -> app_update.asar
      sourceFilePath = version.path
      sourceFilePath = sourceFilePath.replace /\.\//g, ''

      if fileExists path.resolve( path.join(dir, 'app_update.asar') )
        $rootScope.log.entry "Cleaning up previous update"
        fs.unlinkSync path.resolve( path.join(dir, 'app_update.asar') )

      # Fetch the update from the server
      writeStream = fs.createWriteStream(path.join(dir, 'app_update.asar'))
      try
        request("#{LAUNCHER_BASE_URL}/#{sourceFilePath}/app.asar")
          .on 'response', (response) ->
            if response.statusCode == 200
              $rootScope.log.verbose("Response: 200 OK", $rootScope.log.levels.verbose)
              $rootScope.log.verbose("Content length: #{response.headers['content-length']} bytes", $rootScope.log.levels.verbose)
              return

            msg =  null
            msg = "Not Authorized"          if response.statusCode == 401
            msg = "Forbidden"               if response.statusCode == 403
            msg = "Not found"               if response.statusCode == 404
            msg = "Internal Server Error"   if response.statusCode == 500
            msg = "Bad Gateway"             if response.statusCode == 502
            msg = "Service Unavailable"     if response.statusCode == 503
            msg = "Gateway Timeout"         if response.statusCode == 504
            if msg == null
              msg = "Unexpected response (#{response.statusCode})"
            else
              msg = "#{response.statusCode} " + msg

            fetch_failed = true
            reject "Error fetching update  (#{msg})"

          .on 'error', (err) ->
            fetch_failed = true
            return reject("fetch error: #{err.message}")

          .on 'end', ->
            # This event fires even after rejecting; and there's no apparent way to read the response code.
            return  if fetch_failed
            $rootScope.log.update "Successfully fetched update"
            resolve()
          .pipe(writeStream)
      catch e
        reject "Unknown error while fetching update: #{JSON.stringify(e)}"



  applyUpdate = (dir) ->
    return new Promise (resolve, reject) ->
      # app_update.asar -> app.asar

      if not fileExists( path.resolve(path.join(dir, 'app_update.asar')) )
        return reject("Aborting update (app_update.asar does not exist)")


      $rootScope.log.important "Applying update (do not interrupt)"

      stream_update = fs.createReadStream( path.resolve(path.join(dir, 'app_update.asar')) )
      stream_update.on 'error', (err) ->
        $rootScope.log.error "Error reading update"
        reject("update read error: #{err.message}")
        # .on(error) emits after creating the write stream below, which truncates `app.asar`
        $rootScope.log.fatal "Launcher corrupted!  Please reinstall"  ##TODO: backup app.asar
        require('remote').require('app').quit()
        return

      stream_asar = fs.createWriteStream( path.resolve(path.join(dir, 'app.asar')) )
      stream_asar
        .on 'error', (err) ->
          $rootScope.log.error "Error applying update"
          reject("update write error: #{err.message}")
          # creating the write stream truncates `app.asar`
          $rootScope.log.fatal "Launcher corrupted!  Please reinstall"  ##TODO: backup app.asar
          require('remote').require('app').quit()
          return

        .on 'finish', ->
          $rootScope.log.update "Successfully applied update"
          resolve()

      stream_update.pipe(stream_asar)


  cleanupUpdate = (dir) ->
    return new Promise (resolve, reject) ->
      $rootScope.log.entry "Cleaning up post-update"
      fs.unlinkSync path.resolve( path.join(dir, 'app_update.asar') )
      resolve()


  @getChecksums = (pathName) ->
    $q (resolve, reject) ->
      $http.get "#{BASE_URL}/#{pathName}/checksums"
        .success (data) ->
          checksums = []

          lines = data.split "\n"
          # Using .every allows us to "break" out by returning false
          lines.every (line) ->
            return if line == ''

            line.trim()

            hashIndex = line.lastIndexOf ' '
            if hashIndex < 0
              reject "Checksum file invalid [CHECKSUMNOTFOUND]: #{line}"
              return false

            checksum = line.substring(hashIndex, line.length).trim()
            line = line.substring(0, hashIndex).trim()

            sizeIndex = line.lastIndexOf ' '
            if sizeIndex < 0
              reject "Checksum file invalid [SIZENOTFOUND]: #{line}"
              return false

            sizeStr = line.substring(sizeIndex, line.length).trim()
            size = parseFloat sizeStr.trim()
            line = line.substring(0, sizeIndex).trim()

            relativePath = line.trim()

            checksums.push new Checksum(size, checksum, relativePath, "#{BASE_URL}/#{pathName}")

          resolve checksums
        .error (data) ->
          # TODO: Consolidate this to one argument to be consist with how
          # other errors are reported
          reject data, status, headers, config

  @getEula = ->
    $http.get "#{BASE_URL}/smeula.txt"



# @versions cache:
#   Fetch and cache all branches' version data
#   This doubles memory usage but reduces lookup from (http) to O(1)
#
#   .branches['release'] = [{path:,build:,version:,branch:}, ...]
#   .builds[build]       = [{path:,build:,version:,branch:}, ...]
#
#   Note: As a build may exist in multiple branches, e.g. release and dev,
#         `versions.builds[build_id]` will return an array containing at least one version object.

  @versions =
    isReady: () -> return false

    builds:   {}
    branches:
      pre:      []
      dev:      []
      release:  []
      archive:  []
      launcher: []

  # Ready chainable with public resolver
  @versions.ready = new Promise (resolve, reject) => @versions.setReady = resolve
  # Add default handler to update isReady() poll
  @versions.ready.then () => @versions.isReady = () -> return true

  @versions.populate = () =>
    new Promise (resolve, reject) =>
      return resolve()  if @versions.isReady()
      $rootScope.log.verbose "Populating versions"

      versionPromises = []
      ["launcher","pre", "dev", "release", "archive"].forEach (branch) =>
        versionPromises.push new Promise (resolve, reject) =>
          $http.get BRANCH_INDEXES[branch]
            .success (data) =>
              $rootScope.log.entry "Populating versions: #{branch}..."

              # Entry format:  2.0.8#20170712_222922 ./build/starmade-launcher-build_20170712_222922
              lines = data.split '\n'
              lines.forEach (line) =>
                return if line           == ''   # Skip blank     entries
                return if line.charAt(0) == '#'  # Skip commented entries

                tokens   = line.split ' '
                buildstr = tokens[0].split '#'

                # Catch malformed lines
                if tokens.length != 2  || line.split('#').length != 2
                  $rootScope.log.indent.warning "Found malformed version entry:  #{line}"
                  return

                version = {}
                version.version = buildstr[0]
                version.build   = buildstr[1]
                version.path    = tokens[1]
                version.branch  = branch

                # Store via both build id and branch for easy lookup
                @versions.branches[ version.branch ].push version

                # Only store game versions by build
                return  if version.branch == "launcher"


                # Store builds in an array as they can be in multiple branches, e.g. release and dev
                @versions.builds[ version.build ] ||= []
                @versions.builds[ version.build ].push version

              resolve()

            .error (data, status, headers, config) ->
              $rootScope.log.error "Error fetching #{branch} build index"
              $rootScope.log.indent.entry   "Status:  #{status}"
              $rootScope.log.indent.debug   "URL:     #{config['url']}"
              $rootScope.log.indent.verbose "Headers: #{JSON.stringify headers()}"
              $rootScope.log.indent.verbose "Data:    #{JSON.stringify data}"

              # Resolve to allow setting `versions.ready` after populating all branches
              resolve()

      # After caching all of the versions, set ready
      $q.all(versionPromises).then () =>
        $rootScope.log.event "Versions populated"

        @versions.setReady()
        resolve()



  # Get version for a specific branch
  @getVersions = (branch) =>
    # Populate versions if they aren't yet ready
    # This should properly defer execution of all version-dependent code
    prereq = {}
    if @versions.isReady()
      prereq = Promise.resolve()
    else
      prereq = @versions.populate()

    prereq.then () =>
      uniqVersions @versions.branches[branch]


  uniqVersions = (versions) ->
    uniq = []
    return uniq  if versions.length == 0
    versions.forEach (version, index) ->
      if JSON.stringify(versions[index+1]) == JSON.stringify(version)
        return
      uniq.push version
    uniq


  return