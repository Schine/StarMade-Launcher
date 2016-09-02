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
            # $rootScope.log.outdent()
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
            # $rootScope.log.outdent()

          if checkOnly
            updaterProgress.needsUpdating = true
            updaterProgress.inProgress = false
            # $rootScope.log.outdent()
          else
            filesToDownload.forEach (checksum) ->
              q.push checksum, (err) ->
                $rootScope.log.error err if err
            # $rootScope.log.outdent()

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

  @getVersions = (branch) ->
    $q (resolve, reject) ->
      $http.get BRANCH_INDEXES[branch]
        .success (data) ->
          # Entry format:  2.0.8#20170712_222922 ./build/starmade-launcher-build_20170712_222922
          versions = []

          lines = data.split '\n'
          lines.forEach (line) ->
            return if line == ''                  # Skip blank     entries
            return if line.substring(0,1) == '#'  # Skip commented entries

            tokens      = line.split ' '
            build_id  = tokens[0].split '#'

            buildVersion = build_id[0]
            buildBuild   = build_id[1]

            buildPath    = tokens[1]

            # ignore malformed entries:
            return if (!buildPath || !buildVersion || !buildBuild)  # missing segments
            return if buildPath.indexOf('#') >= 0                   # two entries on a line

            versions.push new Version(buildPath, buildVersion, buildBuild)

          resolve uniqVersions(versions)
        .error (data, status, headers, config) ->
          $rootScope.log.error "Error fetching #{branch} build index"
          $rootScope.log.indent.debug   "URL:     #{config['url']}"
          $rootScope.log.indent.debug   "Status:  #{status}"
          $rootScope.log.indent.verbose "Headers: #{JSON.stringify headers}"

          reject data, status, headers, config

  uniqVersions = (versions) ->
    uniq = []
    versions.forEach (version, index) ->
      if JSON.stringify(versions[index+1]) == JSON.stringify(version)
        return
      uniq.push version
    uniq


  return