'use strict'

argv = require('minimist')(process.argv.slice(1))
path = require('path')


# Handle certain single dash arguments
process.argv.slice(1).forEach (arg, index) ->
  argv.archive   = true  if arg == '-archive'
  argv.dev       = true  if arg == '-dev'
  argv.latest    = true  if arg == '-latest'
  argv.nogui     = true  if arg == '-nogui'
  argv.pre       = true  if arg == '-pre'
  argv.release   = true  if arg == '-release'
  argv.help      = true  if arg == '-help'
  argv.debugging = true  if arg == '-debugging'
  if arg == '-verbose'
    argv.debugging = true
    argv.verbose   = true

global.argv = argv


if argv.help?
  buildHash = require('../buildHash.js').buildHash
  version   = require(path.join(__dirname, '..', '..', 'package.json')).version

  console.log "StarMade Launcher v#{version} build #{buildHash}"
  console.log ""
  console.log "Launcher options:"
  console.log " --noupdate          Skip the autoupdate process"
  console.log " --steam             Run in Steam mode             (implies attach, noupdate)"
  console.log " --attach            Attach  to  the game process  (close when the game closes)"
  console.log " --detach            Detach from the game process  (default; supercedes attach)"
  console.log ""
  console.log "Logging options:"
  console.log " --debugging         Increase log-level to include debug entries"
  console.log " --verbose           Increase log-level to include everything"
  console.log " --capture-game-log  Capture the game's output (for troubleshooting; implies attach)"
  console.log ""
  console.log "Advanced options:"
  console.log " --nogui             Immediately update to the newest game version"
  console.log " --cache-dir=\"path\"  Specify a custom cache path"
  process.exit(0)



app           = require('app')
dialog        = require('dialog')
ipc           = require('ipc')
rimraf        = require('rimraf')
shell         = require('shell')
BrowserWindow = require('browser-window')
log           = require('../log.js')


# For some reason, windows open taller on OS X
OSX_HEIGHT_OFFSET = 21




### Update working directory ###
  # osx:        launcher.app/Contents/Resources/app.asar -> launcher.app/Contents/MacOS
  # win/linux:  launcher/resources/app.asar              -> launcher

# Get the current running dir, slicing off everything after "app.asar"
_cwd       = __dirname.split(path.sep)
_pos_asar  = __dirname.toLowerCase().split(path.sep).indexOf("app.asar")
_cwd       = _cwd.slice(0, _pos_asar+1).join(path.sep)
# Backtrack from "app.asar" to the launcher directory, and resolve to an absolute path
_cwd       = path.resolve( path.normalize( path.join(_cwd, "..", "..") ) )  # Two steps back  (launcher/resources/app.asar)

# Account for the differing folder structure on OSX, placing it here: starmade-launcher.app\Contents\MacOS
if process.platform == 'darwin'
  _cwd = path.join(_cwd, "MacOS")

# Update working directory
process.chdir(_cwd)

### End ###



### Update Electron's cache location ###
  # osx:        ~/Library/Application Support/StarMade/Launcher/  ## any changes to the .app directory breaks its codesigning
  # win/linux:  ./.cache/

if process.platform == "darwin"  # osx
  # `app.getPath('appData')` defaults to `~/Library/Application Support`
  cache_path =  path.resolve( path.join(app.getPath('appData'), 'StarMade', 'Launcher') )
else
  cache_path = path.resolve( path.join(".", ".cache") )

# Custom path
if argv['cache-dir']?
  cache_path = path.join(path.resolve(argv['install-dir']), 'StarMade', 'Launcher')


# Update cache locations
app.setPath("appData",  cache_path)
app.setPath("userData", path.join(cache_path, 'userData'))
if argv.verbose?
  console.log "Set appData  cache path to: #{cache_path}"
  console.log "Set userData cache path to: #{path.join(cache_path, 'userData')}"

### End ###



### Logging ###
log_level = log.levels.normal
log_level = log.levels.debug    if argv.debugging
log_level = log.levels.verbose  if argv.verbose

log.set_level(log_level)
# Log entries
ipc.on 'log-entry',     (event, msg, level) => log.entry     msg, level; event.returnValue = true
ipc.on 'log-info',      (event, msg, level) => log.info      msg, level; event.returnValue = true
ipc.on 'log-event',     (event, msg, level) => log.event     msg, level; event.returnValue = true
ipc.on 'log-game',      (event, msg, level) => log.game      msg, level; event.returnValue = true
ipc.on 'log-warning',   (event, msg, level) => log.warning   msg, level; event.returnValue = true
ipc.on 'log-error',     (event, msg, level) => log.error     msg, level; event.returnValue = true
ipc.on 'log-fatal',     (event, msg, level) => log.fatal     msg, level; event.returnValue = true
ipc.on 'log-debug',     (event, msg, level) => log.debug     msg, level; event.returnValue = true
ipc.on 'log-verbose',   (event, msg, level) => log.verbose   msg, level; event.returnValue = true
ipc.on 'log-important', (event, msg, level) => log.important msg, level; event.returnValue = true
ipc.on 'log-update',    (event, msg, level) => log.update    msg, level; event.returnValue = true
ipc.on 'log-end',       (event, msg, level) => log.end       msg, level; event.returnValue = true
ipc.on 'log-raw',       (event, msg, level) => log.raw       msg, level; event.returnValue = true
# Array of log levels
ipc.on 'log-levels',    (event) => event.returnValue = log.levels;
# Indenting functions
ipc.on 'log-indent',    (event, num, level) => log.indent( num, level); event.returnValue = true
ipc.on 'log-outdent',   (event, num, level) => log.outdent(num, level); event.returnValue = true


# On Linux, renderer processes do not inherit the working directory
ipc.on 'cwd',           (event, arg) => event.returnValue = process.cwd()


# app.asar/static
staticDir = path.join(path.dirname(path.dirname(__dirname)), 'static')



authWindow = null
mainWindow = null
gettingStartedWindow = null
updatingWindow = null

authFinished = false
quitting = false



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

  log.verbose "Opening Window: Main"
  mainWindow.loadUrl "file://#{staticDir}/index.html"
  mainWindow.openDevTools()  if argv.development

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
  gettingStartedWindow.openDevTools()  if argv.development

  gettingStartedWindow.on 'close', ->
    if authWindow?
      # User was looking at licenses
      return
    else if mainWindow?
      # User was being asked to link with Steam
      mainWindow.show()
    else
      # Getting started process finished
      log.verbose "Finished Initial Setup"
      openMainWindow()

  gettingStartedWindow.on 'closed', ->
    gettingStartedWindow = null

app.on 'window-all-closed', ->
  log.end "All windows closed.  Exiting."
  app.quit()

app.on 'ready', ->
  protocol = require('protocol')

  openGettingStartedWindow()

app.on 'before-quit', ->
  log.end "Exiting"
  quitting = true

ipc.on 'open-licenses', ->
  log.verbose "Opening Window: Licenses"
  openGettingStartedWindow('licenses')

ipc.on 'open-updating', ->
  log.verbose "Opening Window: Update"
  mainWindow.hide()
  authWindow.hide()
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

  log.verbose "Opening Window: Auth"
  authWindow.loadUrl "file://#{staticDir}/auth.html"
  authWindow.openDevTools()  if argv.development

  authWindow.on 'closed', ->
    authWindow = null
    if mainWindow? && !mainWindow.isVisible() && !authFinished
      mainWindow.close()

ipc.on 'finish-auth', (event, args) ->
  authFinished = true
  log.event "Finished Auth"

  if authWindow?
    authWindow.close()
  else
    log.warning 'finish-auth was triggered when authWindow is null!'

  mainWindow.webContents.send 'finish-auth', args

ipc.on 'start-steam-link', ->
  log.verbose "Opening Window: Steam Link"
  openGettingStartedWindow('steam')
