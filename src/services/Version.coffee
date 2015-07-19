'use strict'

app = angular.module 'launcher'

app.factory 'Version', ->
  class Version
    constructor: (@path, @version, @build) ->
