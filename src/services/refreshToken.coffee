'use strict'

app = angular.module 'launcher'

app.service 'refreshToken', ($http, $q) ->
  REGISTRY_TOKEN_URL = 'https://registry.star-made.org/oauth/token'

  @get = ->
    localStorage.getItem 'refreshToken'

  @set = (token) ->
    localStorage.setItem 'refreshToken', token

  @refresh = ->
    $q (resolve, reject) =>
      refreshToken = @get()
      reject 'No refresh token is set' unless refreshToken?

      $http.post REGISTRY_TOKEN_URL,
        grant_type: 'refresh_token'
        refresh_token: refreshToken
      .success (data) ->
        resolve data
      .error (data) ->
        reject data

  @delete = ->
    localStorage.removeItem 'refreshToken'

  return
