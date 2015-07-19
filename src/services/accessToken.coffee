'use strict'

app = angular.module 'launcher'

app.service 'accessToken', ->
  @get = ->
    localStorage.getItem 'accessToken'

  @set = (token) ->
    localStorage.setItem 'accessToken', token

  @delete = ->
    localStorage.removeItem 'accessToken'

  return
