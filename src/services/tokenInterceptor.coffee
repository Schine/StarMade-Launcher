'use strict'

app = angular.module 'launcher'

app.factory 'tokenInterceptor', (accessToken, apiConfig) ->
  request: (config) ->
    if config.url.indexOf "//#{apiConfig.baseUrl}" == 0
      token = accessToken.get()
      config.headers.Authorization = 'Bearer ' + token if token

    config
