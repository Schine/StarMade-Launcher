'use strict'

_ = require('underscore')
angular = require('angular')
async = require('async')

app = angular.module 'launcher'

app.service 'updater', ($q, $http, Checksum, Version) ->
  BASE_URL = 'http://files.star-made.org'
  BRANCH_INDEXES =
    pre: "#{BASE_URL}/prebuildindex"
    dev: "#{BASE_URL}/devbuildindex"
    release: "#{BASE_URL}/releasebuildindex"
    archive: "#{BASE_URL}/archivebuildindex"

  @update = (version, installDir) ->
    console.log 'Getting checksums'
    @getChecksums(version.path)
      .then (checksums) ->
        filesToDownload = []
        download = _.after checksums.length, ->
          q = async.queue (checksum, callback) ->
            checksum.download installDir
              .then ->
                callback null
              , (err) ->
                callback err
          , 5

          q.drain = ->
            console.log 'All files downloaded'

          filesToDownload.forEach (checksum) ->
            q.push checksum, (err) ->
              console.error err if err

        console.log 'Determining files to download...'
        totalSize = 0
        checksums.forEach (checksum) ->
          totalSize += checksum.size

        p = 1.0 / checksums.length
        g = 0.0

        checksums.forEach (checksum) ->
          checksum.checkLocal installDir
            .then (needsDownloading) ->
              filesToDownload.push(checksum) if needsDownloading
              g++
              console.log "Determining files to download... #{g * p * 100.0}%  selected #{filesToDownload.length}/#{checksums.length} (#{totalSize / 1024 / 1024} MB)"
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
