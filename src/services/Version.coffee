'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.factory 'Version', ->
  class Version
    constructor: (@path, @version, @build) ->
