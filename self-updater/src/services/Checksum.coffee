'use strict'

async = require('async')
crypto = require('crypto')
fs = require('original-fs')
mkdirp = require('mkdirp')
request = require('request')

app = angular.module 'launcher-self-updater'

app.factory 'Checksum', ($q, updaterProgress) ->
  class Checksum
    constructor: (@mode, @size, @checksum, @relativePath, @buildPath) ->

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
      sourceFilePath = sourceFilePath.replace /\.\//g, ''
      dest = "#{installDir}/#{@relativePath}"

      console.log "Downloading #{sourceFilePath} -> #{dest}"

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
              .on 'end', =>
                fs.chmod dest, @mode, ->
                  updaterProgress.filesDone += 1
                  updaterProgress.updateText()
                  resolve()
                  callback null
              .pipe fs.createWriteStream dest
        ]
