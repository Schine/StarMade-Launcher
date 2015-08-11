'use strict'

app = angular.module 'launcher'

app.factory 'NewsSidebarEntry', ($resource, apiConfig) ->
  $resource "https://#{apiConfig.baseUrl}/api/v1/launcher/news_sidebar_entries/:id.json", {id: '@id'}
