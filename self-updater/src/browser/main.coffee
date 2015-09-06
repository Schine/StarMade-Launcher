'use strict'

app = require('app')
path = require('path')
BrowserWindow = require('browser-window')

global.argv = require('minimist')(process.argv.slice(1))
staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')

mainWindow = null

# Disable caching so that files like the build index and checksums aren't cached
app.commandLine.appendSwitch('disable-http-cache')

app.on 'ready', ->
  height = 550
  height -= OSX_HEIGHT_OFFSET if process.platform == 'darwin'

  mainWindow = new BrowserWindow
    frame: true
    resizable: false
    width: 800
    height: height

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.openDevTools()

  mainWindow.on 'closed', ->
    mainWindow = null

app.on 'window-all-closed', ->
  app.quit()
