'use strict'

_ = require('underscore')
angular = require('angular')
async = require('async')

app = angular.module 'launcher'

app.service 'updater', ($q, $http, Checksum, Version, updaterProgress) ->
  BASE_URL = 'http://files.star-made.org'
  BRANCH_INDEXES =
    pre: "#{BASE_URL}/prebuildindex"
    dev: "#{BASE_URL}/devbuildindex"
    release: "#{BASE_URL}/releasebuildindex"
    archive: "#{BASE_URL}/archivebuildindex"

  @update = (version, installDir) ->
    updaterProgress.curValue = 0
    updaterProgress.inProgress = true
    updaterProgress.text = 'Getting checksums'

    @getChecksums(version.path)
      .then (checksums) ->
        filesToDownload = []

        download = _.after checksums.length, ->
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

          filesToDownload.forEach (checksum) ->
            q.push checksum, (err) ->
              console.error err if err

        updaterProgress.text = 'Determining files to download...'
        updaterProgress.curValue = 0
        updaterProgress.maxValue = checksums.length

        totalSize = 0
        checksums.forEach (checksum) ->
          totalSize += checksum.size

        checksums.forEach (checksum) ->
          checksum.checkLocal installDir
            .then (needsDownloading) ->
              filesToDownload.push(checksum) if needsDownloading
              updaterProgress.text = "Determining files to download... #{updaterProgress.calculatePercentage()}%  selected #{filesToDownload.length}/#{checksums.length} (#{updaterProgress.toMegabytes(totalSize)} MB)"
              updaterProgress.curValue++
              download()

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

            vPath = line.split ' '
            vBuild = vPath[0].split '#'

            version = vBuild[0]
            build = vBuild[1]

            path = vPath[1]

            versions.push new Version(path, version, build)

          resolve versions
        .error (data, status, headers, config) ->
          reject data, status, headers, config

  return
