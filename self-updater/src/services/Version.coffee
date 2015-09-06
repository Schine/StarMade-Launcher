'use strict'

app = angular.module 'launcher-self-updater'

app.factory 'Version', ->
  class Version
    constructor: (@path, @version, @build) ->
