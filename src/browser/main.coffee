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
    width: 800
    height: 600

  mainWindow.loadUrl "file://#{staticDir}/index.html"

  mainWindow.on 'closed', ->
    mainWindow = null
