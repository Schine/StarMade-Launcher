'use strict'

path       = require('path')
BigNumber  = require('bignumber.js')
greenworks = require(path.resolve(path.join('dep','greenworks','greenworks.js')))

STEAM64_32_DIFFERENCE = '76561197960265728'


exports.initialized = false

exports.init = ->
  # Initialize with Steam. Since Steam is optional, we will just return if this fails.
  return unless greenworks.initAPI()

  exports.initialized = true

exports.greenworks = greenworks

exports.steamId = ->
  new BigNumber(greenworks.getSteamId().accountId).plus(STEAM64_32_DIFFERENCE)
