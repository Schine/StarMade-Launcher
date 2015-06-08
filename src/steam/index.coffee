'use strict'

path = require('path')

unless process.platform == 'darwin'
  greenworks = require(path.resolve('dep/greenworks/greenworks'))

exports.init = ->
  # No 64-bit binary of Steamworks on OS X
  return if process.platform == 'darwin'

  # Initialize with the Steam. Since Steam is optional, we will just return
  # if this fails.
  return unless greenworks.initAPI()
