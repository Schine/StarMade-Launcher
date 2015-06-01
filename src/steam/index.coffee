'use strict'

path = require('path')

greenworks = require(path.resolve('dep/greenworks/greenworks'))

exports.init = ->
  # Initialize with the Steam. Since Steam is optional, we will just return
  # if this fails.
  return unless greenworks.initAPI()
