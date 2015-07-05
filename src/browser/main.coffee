'use strict'

# For some reason, windows open taller on OS X
OSX_HEIGHT_OFFSET = 44

app = require('app')
dialog = require('dialog')
ipc = require('ipc')
path = require('path')
rimraf = require('rimraf')
shell = require('shell')
BrowserWindow = require('browser-window')

if process.platform == 'darwin' && process.cwd() == '/'
  # Change working directory
  process.chdir(path.join(path.dirname(path.dirname(path.dirname(path.dirname(__dirname)))), 'MacOS'))

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')

authWindow = null
mainWindow = null
gettingStartedWindow = null

authFinished = false
quitting = false

oldUserData = app.getPath 'userData'
app.setPath 'userData', "#{app.getPath('appData')}/StarMade/Launcher"
rimraf oldUserData, (err) ->
  console.warn "Unable to remove old user data directory: #{err}" if err

openMainWindow = ->
  return if quitting

  height = 550
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  mainWindow = new BrowserWindow
    frame: false
    resizable: false
    show: false
    width: 800
    height: height

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

openGettingStartedWindow = (args) ->
  return if quitting

  height = 504
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  gettingStartedWindow = new BrowserWindow
    frame: false
    resizable: false
    show: false
    width: 650
    height: height

  gettingStartedWindow.loadUrl "file://#{staticDir}/getting_started.html?#{args}"
  gettingStartedWindow.openDevTools()

  gettingStartedWindow.on 'close', ->
    if authWindow?
      # User was looking at licenses
      return
    else if mainWindow?
      # User was being asked to link with Steam
      mainWindow.show()
    else
      # Getting started process finished
      openMainWindow()

  gettingStartedWindow.on 'closed', ->
    gettingStartedWindow = null

app.on 'window-all-closed', ->
  app.quit()

app.on 'ready', ->
  protocol = require('protocol')

  openGettingStartedWindow()

app.on 'before-quit', ->
  quitting = true

ipc.on 'open-licenses', ->
  openGettingStartedWindow('licenses')

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
    if mainWindow? && !mainWindow.isVisible() && !authFinished
      mainWindow.close()

ipc.on 'finish-auth', (event, args) ->
  authFinished = true

  if authWindow?
    authWindow.close()
  else
    console.warn 'finish-auth was triggered when authWindow is null!'

  mainWindow.webContents.send 'finish-auth', args

ipc.on 'start-steam-link', ->
  openGettingStartedWindow('steam')
