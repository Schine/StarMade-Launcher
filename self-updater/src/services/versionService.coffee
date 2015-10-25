_ = require('underscore')
async = require('async')e

app = angular.module 'launcher-self-updater'

app.service 'versionService', ($q, $http) ->

  VERSIONS_URL = "https://registry.star-made.org/api/v1/launcher/versions.json"

  @getVersions = (releasesOnly = true) -> $http.get VERSIONS_URL

  @getManifestForVersion = (version) ->
    def = $q.defer()

    @getVersions().then (obj) ->
      def.resolve _.find obj.data, (v) -> v.version == version

    def.promise


  # Must have a return on the final line to make a service work correctly
  return
