'use strict'

BigNumber = require('bignumber.js')
path = require('path')

STEAM64_32_DIFFERENCE = '76561197960265728'

unless process.platform == 'darwin'
  greenworks = require(path.resolve('dep/greenworks/greenworks'))

exports.initialized = false

exports.init = ->
  # No 64-bit binary of Steamworks on OS X
  return if process.platform == 'darwin'

  # Initialize with the Steam. Since Steam is optional, we will just return
  # if this fails.
  return unless greenworks.initAPI()

  exports.initialized = true

exports.greenworks = greenworks

exports.steamId = ->
  new BigNumber(greenworks.getSteamId().accountId).plus(STEAM64_32_DIFFERENCE)
