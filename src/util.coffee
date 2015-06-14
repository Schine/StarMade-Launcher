'use strict'

exports.setupExternalLinks = ->
  shell = require('shell')
  
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

exports.parseJreVersion = (javaVersion) ->
  javaVersionBits = javaVersion.split('u')
  javaVersionNumber = "1.#{javaVersionBits[0]}.0"
  javaUpdateNumber = javaVersionBits[1]

  "jre#{javaVersionNumber}_#{javaUpdateNumber}"
