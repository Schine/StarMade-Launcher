'use strict'

app = angular.module 'launcher'

app.constant 'apiConfig',
  baseUrl: 'registry.star-made.org'
  clientId: 'f23be50e1683f7b490d10e230a0bbaef01eee8ac9d43e7eb0ed240e5f669df52'
  redirectUri: 'starmade://auth/callback'
  scopes: 'public+read_citizen_info+write'

app.service 'api', ($http, apiConfig) ->
  @getBaseUrl = ->
    apiConfig.baseUrl

  @getAuthorizeUrl = ->
    authorizeUrl = "https://#{apiConfig.baseUrl}/oauth/authorize?"
    authorizeUrl += 'response_type=token'
    authorizeUrl += '&client_id=' + apiConfig.clientId
    authorizeUrl += '&redirect_uri=' + apiConfig.redirectUri
    authorizeUrl += '&scope=' + apiConfig.scopes
    authorizeUrl

  @get = (relativeUrl) ->
    $http.get "https://#{apiConfig.baseUrl}/api/v1/#{relativeUrl}"

  @put = (relativeUrl, data, config) ->
    $http.put "https://#{apiConfig.baseUrl}/api/v1/#{relativeUrl}", data, config

  @getCurrentUser = ->
    @get 'users/me.json'

  @updateCurrentUser = (data) ->
    delete data.admin
    @put 'users/me.json', data

  @isAuthenticated = ->
    !!localStorage.getItem 'accessToken'

  return
