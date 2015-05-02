'use strict'

app = require('app')
ipc = require('ipc')
path = require('path')
BrowserWindow = require('browser-window')

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')
mainWindow = null

app.on 'window-all-closed', ->
  app.quit()

app.on 'ready', ->
  mainWindow = new BrowserWindow
    frame: false
    resizable: false
    width: 1200
    height: 750

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

ipc.on 'minimize-window', ->
  mainWindow.minimize()
