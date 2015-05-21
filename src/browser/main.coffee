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
    show: false
    width: 1200
    height: 750

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

ipc.on 'start-auth', ->
  authWindow = new BrowserWindow
    frame: false
    resizable: false
    width: 400
    height: 500

  mainWindow.hide()

  authWindow.loadUrl "file://#{staticDir}/auth.html"

  authWindow.on 'closed', ->
    authWindow = null

ipc.on 'finish-auth', (event, args) ->
  if authWindow?
    authWindow.close()
  else
    console.warn 'finish-auth was triggered when authWindow is null!'

  mainWindow.webContents.send 'finish-auth', args
