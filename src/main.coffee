'use strict'

ipc = require('ipc')
$ = require('jquery')

$ ->
  $('.window-controls .minimize a').click ->
    ipc.send 'minimize-window'

  $('.window-controls .close a').click ->
    window.close()
