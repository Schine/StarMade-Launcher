'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.factory 'Checksum', ->
  class Checksum
    constructor: (@size, @checksum, @relativePath) ->
