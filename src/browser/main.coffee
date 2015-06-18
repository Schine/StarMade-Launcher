'use strict'

# For some reason, windows open taller on OS X
OSX_HEIGHT_OFFSET = 44

app = require('app')
dialog = require('dialog')
ipc = require('ipc')
path = require('path')
shell = require('shell')
BrowserWindow = require('browser-window')

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')

authWindow = null
mainWindow = null
gettingStartedWindow = null

app.setPath 'userData', "#{app.getPath('appData')}/StarMade/Launcher"

openMainWindow = ->
  height = 750
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  mainWindow = new BrowserWindow
    frame: false
    resizable: false
    show: false
    width: 1200
    height: height

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  #mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

openGettingStartedWindow = (args) ->
  height = 504
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  gettingStartedWindow = new BrowserWindow
    frame: false
    resizable: false
    show: false
    width: 650
    height: height

  gettingStartedWindow.loadUrl "file://#{staticDir}/getting_started.html?#{args}"
  #gettingStartedWindow.openDevTools()

  gettingStartedWindow.on 'close', ->
    if mainWindow?
      mainWindow.show()
    else
      openMainWindow()

  gettingStartedWindow.on 'closed', ->
    gettingStartedWindow = null

app.on 'window-all-closed', ->
  app.quit()

app.on 'ready', ->
  protocol = require('protocol')

  openGettingStartedWindow()

ipc.on 'open-licenses', ->
  licensesWindow = new BrowserWindow
    width: 800
    height: 600

  licensesWindow.loadUrl "file://#{staticDir}/licenses.txt"

ipc.on 'start-auth', ->
  height = 404
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  authWindow = new BrowserWindow
    frame: false
    resizable: false
    width: 255
    height: height

  mainWindow.hide()

  authWindow.loadUrl "file://#{staticDir}/auth.html"
  #authWindow.openDevTools()

  authWindow.on 'closed', ->
    authWindow = null

ipc.on 'finish-auth', (event, args) ->
  if authWindow?
    authWindow.close()
  else
    console.warn 'finish-auth was triggered when authWindow is null!'

  mainWindow.webContents.send 'finish-auth', args

ipc.on 'start-steam-link', ->
  openGettingStartedWindow('steam')
