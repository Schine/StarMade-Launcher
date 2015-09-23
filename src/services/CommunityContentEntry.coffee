'use strict'

app = angular.module 'launcher'

app.factory 'CommunityContentEntry', ($resource, apiConfig) ->
  $resource "https://#{apiConfig.baseUrl}/api/v1/launcher/community_content_entries/:id.json", {id: '@id'}
