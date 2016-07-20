'use strict'

# For some reason, windows open taller on OS X
OSX_HEIGHT_OFFSET = 21

app = require('app')
dialog = require('dialog')
ipc = require('ipc')
path = require('path')
rimraf = require('rimraf')
shell = require('shell')
BrowserWindow = require('browser-window')

argv = require('minimist')(process.argv.slice(1))



### Update Electron's cache location ###

# Get the current running dir, slicing off everything after "app.asar"
_cwd       = __dirname.split(path.sep)
_pos_asar = __dirname.toLowerCase().split(path.sep).indexOf("app.asar")
_cwd       = _cwd.slice(0, _pos_asar+1).join(path.sep)

# Backtrack from "app.asar" to the launcher directory, and resolve to an absolute path
_cwd = path.resolve( path.normalize( path.join(_cwd, "..", "..") ) )  # Two steps back  (launcher/resources/app.asar)

# Join the new cache directory
cache_path = path.resolve( path.join(_cwd, ".cache") )

# Update cache locations
app.setPath("appData",  cache_path)
app.setPath("userData", path.join(cache_path, 'userData'))

### End ###




# Handle certain single dash arguments
process.argv.slice(1).forEach (arg, index) ->
  argv.archive = true if arg == '-archive'
  argv.dev = true if arg == '-dev'
  argv.latest = true if arg == '-latest'
  argv.nogui = true if arg == '-nogui'
  argv.pre = true if arg == '-pre'
  argv.release = true if arg == '-release'

global.argv = argv

if process.platform == 'darwin' && process.cwd() == '/'
  # Change working directory
  process.chdir(path.join(path.dirname(path.dirname(path.dirname(path.dirname(__dirname)))), 'MacOS'))

staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')

authWindow = null
mainWindow = null
gettingStartedWindow = null
updatingWindow = null

authFinished = false
quitting = false

oldUserData = app.getPath 'userData'

if argv['install-dir']?
  app.setPath 'userData', path.join(path.resolve(argv['install-dir']), 'Launcher')
else
  if process.platform == 'linux'
    # Use the user's home directory on Linux
    app.setPath 'userData', "#{app.getPath('home')}/StarMade/Launcher"
  else
    app.setPath 'userData', "#{app.getPath('appData')}/StarMade/Launcher"

rimraf oldUserData, (err) ->
  console.warn "Unable to remove old user data directory: #{err}" if err

# Disable caching so that files like the build index and checksums aren't cached
app.commandLine.appendSwitch('disable-http-cache')

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
  # mainWindow.openDevTools()  if argv.development

  #if argv['install-dir']?
  #  escapedInstallDir = path.resolve(argv['install-dir']).replace(/\\/g, '\\\\')
  #  mainWindow.webContents.executeJavaScript("localStorage.setItem('installDir', '#{escapedInstallDir}');")

  #if argv.archive
  #  mainWindow.webContents.executeJavaScript("localStorage.setItem('branch', 'archive');")

  #if argv.dev
  #  mainWindow.webContents.executeJavaScript("localStorage.setItem('branch', 'dev');")

  #if argv.pre
  #  mainWindow.webContents.executeJavaScript("localStorage.setItem('branch', 'pre');")

  #if argv.release
  #  mainWindow.webContents.executeJavaScript("localStorage.setItem('branch', 'release');")

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

  # Pass steam flag for automated install directory selection
  gettingStartedWindow.steamLaunch = !!argv.steam

  gettingStartedWindow.loadUrl "file://#{staticDir}/getting_started.html?#{args}"

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

ipc.on 'open-updating', ->
  openGettingStartedWindow('updating')

ipc.on 'updating-opened', ->
  mainWindow.webContents.send('updating-opened')

ipc.on 'close-updating', ->
  gettingStartedWindow.close()

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
