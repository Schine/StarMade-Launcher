'use strict'

app = require('app')
dialog = require('dialog')
ipc = require('ipc')
path = require('path')
shell = require('shell')
BrowserWindow = require('browser-window')

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')

authWindow = null
mainWindow = null

app.setPath 'userData', "#{app.getPath('appData')}/StarMade/Launcher"

app.on 'window-all-closed', ->
  app.quit()

app.on 'ready', ->
  protocol = require('protocol')

  mainWindow = new BrowserWindow
    frame: false
    resizable: false
    width: 1200
    height: 750

  entry = "file://#{staticDir}/index.html"

  protocol.registerProtocol 'starmade', (request) ->
    if request.url.indexOf('starmade://auth/callback') != -1
      if authWindow
        authWindow.close()

      mainWindow.loadUrl "#{entry}#{request.url.substr(24)}"
    return new protocol.RequestFileJob(entry)

  mainWindow.loadUrl entry

  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

ipc.on 'start-auth', (event, authorizeUrl) ->
  authWindow = new BrowserWindow
    'node-integration': false
    width: 600
    height: 700

  authWindow.loadUrl authorizeUrl

  authWindow.on 'closed', ->
    authWindow = null
