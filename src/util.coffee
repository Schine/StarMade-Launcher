'use strict'

exports.setupExternalLinks = ->
  shell = require('electron').shell

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

exports.getJreDirectory = (javaVersion, platform = process.platform) ->
    jreDirectory = "jre#{javaVersion}"
    if platform == 'darwin'
      jreDirectory += '.jre/Contents/Home'
    else
      jreDirectory