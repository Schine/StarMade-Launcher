'use strict'

app = require('app')
dialog = require('dialog')
ipc = require('ipc')
path = require('path')
shell = require('shell')
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

ipc.on 'third-party-warning', (event, href) ->
  dialog.showMessageBox
    type: 'info'
    buttons: [
      'OK'
      'Cancel'
    ]
    title: 'Third Party Website'
    message: 'You are about to visit a third party website. Schine GmbH does not take any responsibility for any content on third party sites.'
    (response) ->
      shell.openExternal href if response == 0
