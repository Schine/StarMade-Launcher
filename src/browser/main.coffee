'use strict'

app = require('app')
path = require('path')
BrowserWindow = require('browser-window')

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')
mainWindow = null

app.on 'window-all-closed', ->
  if process.platform != 'darwin'
    app.quit()

app.on 'ready', ->
  mainWindow = new BrowserWindow
    frame: false
    width: 1200
    height: 750

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.on 'closed', ->
    mainWindow = null
