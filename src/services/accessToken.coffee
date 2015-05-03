'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.service 'accessToken', ->
  @get = ->
    console.warn 'accessToken.get is not implemented'

  @set = (token) ->
    console.warn 'accessToken.set is not implemented'
    console.log "If implemented, access token would have been set to #{token}"

  @delete = ->
    console.warn 'accessToken.delete is not implemented'

  return
