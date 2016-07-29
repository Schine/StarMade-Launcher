'use strict'

_ = require('underscore')
async = require('async')
fs = require('original-fs')
ipc = require('ipc')
request = require('request')


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

    $rootScope.log.entry "Updating game..."

    $rootScope.log.indent()
    $rootScope.log.info  "(checkOnly)"  if checkOnly
    $rootScope.log.info  "(forced)"     if force
    $rootScope.log.outdent()


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
            $rootScope.log.entry "Up to date"
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
            $rootScope.log.entry "All files downloaded"
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
    $q (resolve, reject) ->
      sourceFilePath = version.path
      sourceFilePath = sourceFilePath.replace /\.\//g, ''

      resourcesDir = null
      if process.platform == 'darwin'
        resourcesDir = path.join launcherDir, '..', 'Resources'
      else
        resourcesDir = path.join launcherDir, 'resources'
      console.info resourcesDir

      request("#{LAUNCHER_BASE_URL}/#{sourceFilePath}/app.asar")
        .on 'error', (err) ->
          reject(err)
        .on 'end', ->
          resolve()
        .pipe(fs.createWriteStream(path.join(resourcesDir, 'app.asar')))

  @getChecksums = (path) ->
    $q (resolve, reject) ->
      $http.get "#{BASE_URL}/#{path}/checksums"
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

            checksums.push new Checksum(size, checksum, relativePath, "#{BASE_URL}/#{path}")

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
          versions = []

          lines = data.split '\n'
          lines.forEach (line) ->
            return if line == ''
            return if line.substring(0,1) == '#'  # commented version entry

            vPath   = line.split ' '
            vBuild  = vPath[0].split '#'

            version = vBuild[0]
            build   = vBuild[1]

            path    = vPath[1]

            # ignore malformed entries:
            return if (!path || !version || !build)  # missing segments
            return if path.indexOf('#') >= 0         # two entries on a line

            versions.push new Version(path, version, build)

          resolve uniqVersions(versions)
        .error (data, status, headers, config) ->
          reject data, status, headers, config

  uniqVersions = (versions) ->
    uniq = []
    versions.forEach (version, index) ->
      if JSON.stringify(versions[index+1]) == JSON.stringify(version)
        return
      uniq.push version
    uniq


  return