'use strict'

shell = require('shell')

exports.setupExternalLinks = ->
  externalLinks = document.getElementsByClassName 'external'

  Array.prototype.forEach.call externalLinks, (link) ->
    link.addEventListener 'click', (event) ->
      event.preventDefault()

      shell.openExternal this.href

exports.parseBoolean = (str) ->
  if str == 'true'
    true
  else
    false
