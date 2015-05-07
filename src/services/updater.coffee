'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.service 'updater', ($q, $http, Version) ->
  BASE_URL = 'http://files.star-made.org'
  BRANCH_INDEXES =
    pre: "#{BASE_URL}/prebuildindex"
    dev: "#{BASE_URL}/devbuildindex"
    release: "#{BASE_URL}/releasebuildindex"
    archive: "#{BASE_URL}/archivebuildindex"

  @getVersions = (branch) ->
    $q (resolve, reject) ->
      $http.get BRANCH_INDEXES[branch]
        .success (data) ->
          versions = []

          lines = data.split '\n'
          lines.forEach (line) ->
            return if line == ''

            vPath = line.split ' '
            vBuild = vPath[0].split '#'

            version = vBuild[0]
            build = vBuild[1]

            path = vPath[1]

            versions.push new Version(path, version, build)

          resolve versions
        .error (data, status, headers, config) ->
          reject data, status, headers, config

  return
