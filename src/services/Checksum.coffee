'use strict'

async = require('async')
crypto = require('crypto')
fs = require('fs')
mkdirp = require('mkdirp')
request = require('request')

app = angular.module 'launcher'

app.factory 'Checksum', ($q, $rootScope, updaterProgress) ->
  class Checksum
    constructor: (@size, @checksum, @relativePath, @buildPath) ->

    checkLocal: (installDir) ->
      $q (resolve) =>
        hash = crypto.createHash 'sha1'

        dest = "#{installDir}/#{@relativePath}"
        stream = fs.createReadStream dest

        stream.on 'error', =>
          $rootScope.log.entry "#{@relativePath} does not exist"
          resolve true

        stream.on 'data', (data) ->
          hash.update data, 'utf8'

        stream.on 'end', =>
          localChecksum = hash.digest 'hex'
          if localChecksum != @checksum
            $rootScope.log.entry "Checksum differs for #{@relativePath}"
            resolve true
          else
            $rootScope.log.verbose "Not downloading #{@relativePath}"
            resolve false

    download: (installDir) ->
      sourceFilePath = "#{@buildPath}/#{@relativePath}"
      dest = "#{installDir}/#{@relativePath}"

      $rootScope.log.entry "Downloading: #{sourceFilePath}"
      $rootScope.log.indent()
      $rootScope.log.entry("To local: #{dest}", $rootScope.log.levels.debug)
      $rootScope.log.outdent()

      $q (resolve, reject) =>
        async.series [
          (callback) ->
            destBits = dest.split '/'
            destFolder = dest.replace destBits[destBits.length - 1], ''
            mkdirp destFolder, callback
          (callback) =>
            bytesReceived = 0
            request
              .get sourceFilePath
              .on 'error', (err) =>
                updaterProgress.curValue += @size - bytesReceived
                updaterProgress.filesDone += 1
                updaterProgress.updateText()
                reject err
                callback err
              .on 'data', (chunk) ->
                bytesReceived += chunk.length
                updaterProgress.curValue += chunk.length
                updaterProgress.updateText()
              .on 'end', ->
                updaterProgress.filesDone += 1
                updaterProgress.updateText()
                resolve()
                callback null
              .pipe fs.createWriteStream dest
        ]
