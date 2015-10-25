exports.init = ->
  return

  exports.initialized = true

exports.greenworks = greenworks

exports.steamId = ->
  new BigNumber(greenworks.getSteamId().accountId).plus(STEAM64_32_DIFFERENCE)
