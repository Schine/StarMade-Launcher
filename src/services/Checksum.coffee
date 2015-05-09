'use strict'

angular = require('angular')
async = require('async')
crypto = require('crypto')
fs = require('fs')
mkdirp = require('mkdirp')
request = require('request')

app = angular.module 'launcher'

app.factory 'Checksum', ($q, paths) ->
  class Checksum
    constructor: (@size, @checksum, @relativePath, @buildPath) ->

    checkLocal: (installDir) ->
      $q (resolve) =>
        hash = crypto.createHash 'sha1'

        dest = "#{installDir}/#{@relativePath}"
        stream = fs.createReadStream dest

        stream.on 'error', =>
          console.log "#{@relativePath} does not exist"
          resolve true

        stream.on 'data', (data) ->
          hash.update data, 'utf8'

        stream.on 'end', =>
          localChecksum = hash.digest 'hex'
          if localChecksum != @checksum
            console.log "Checksum differs for #{@relativePath}"
            resolve true
          else
            console.log "Not downloading #{@relativePath}"
            resolve false

    download: (installDir) ->
      sourceFilePath = "#{@buildPath}/#{@relativePath}"
      dest = "#{installDir}/#{@relativePath}"

      console.log "Downloading #{sourceFilePath} -> #{dest}"

      $q (resolve, reject) ->
        async.series [
          (callback) ->
            destBits = dest.split '/'
            destFolder = dest.replace destBits[destBits.length - 1], ''
            mkdirp destFolder, callback
          (callback) ->
            request
              .get sourceFilePath
              .on 'data', (chunk) ->
                # TODO: Pass the received chunk size to the GUI
                return
              .on 'end', ->
                resolve()
                callback null
              .pipe fs.createWriteStream dest
        ]
