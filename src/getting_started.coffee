'use strict'

fs = require('fs')
ipc = require('ipc')
path = require('path')
remote = require('remote')
dialog = remote.require('dialog')
electronApp = remote.require('app')
shell = require('shell')

util = require('./util')

close = document.getElementById 'close'
footerLinks = document.getElementById 'footerLinks'
currentStep = -1


step0 = document.getElementById 'step0'
step1 = document.getElementById 'step1'
step2 = document.getElementById 'step2'
step3 = document.getElementById 'step3'
step4 = document.getElementById 'step4'
updating = document.getElementById 'updating'

showLicenses = ->
  close.style.display = 'none'
  step0.style.display = 'block'
  step1.style.display = 'none'
  step2.style.display = 'none'
  step3.style.display = 'none'
  step4.style.display = 'none'
  updating.style.display = 'none'
  footerLinks.style.display = 'none'

showUpdating = ->
  step0.style.display = 'none'
  updating.style.display = 'block'

acceptEula = ->
  localStorage.setItem 'acceptedEula', true
  close.style.display = 'inline'
  footerLinks.style.display = 'block'

  switch currentStep
    when -1
      window.close()
    when 0, 1
      currentStep = 1
      step0.style.display = 'none'
      step1.style.display = 'block'
    when 2
      step0.style.display = 'none'
      step2.style.display = 'block'
    when 3
      step0.style.display = 'none'
      step3.style.display = 'block'
    when 4
      step0.style.display = 'none'
      step4.style.display = 'block'


close.addEventListener 'click', ->
  remote.require('app').quit()

if localStorage.getItem('gotStarted')?
  if window.location.href.split('?')[1] == 'licenses'
    showLicenses()
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'steam'
    currentStep = 4
    step0.style.display = 'none'
    step3.style.display = 'block'
    footerLinks.style.display = 'block'
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'updating'
    showUpdating()
    ipc.send('updating-opened')
    remote.getCurrentWindow().show()
  else
    window.close()
    return
else
  currentStep = 0
  acceptEula() if localStorage.getItem('acceptedEula')?
  remote.getCurrentWindow().show()

util.setupExternalLinks()

#
# Step 0 (Licenses)
#

licenses = document.getElementById 'licenses'
accept = document.getElementById 'accept'
acceptBg = document.getElementById 'acceptBg'
decline = document.getElementById 'decline'
declineBg = document.getElementById 'declineBg'

fs.readFile path.join(path.dirname(__dirname), 'static', 'licenses.txt'), (err, data) ->
  if err
    console.warn 'Unable to open licenses.txt'
    acceptEula()

  licenses.innerHTML = '\n\n\n' + data

accept.addEventListener 'mouseenter', ->
  acceptBg.className = 'hover'

accept.addEventListener 'mouseleave', ->
  acceptBg.className = ''

accept.addEventListener 'click', ->
  acceptEula()

decline.addEventListener 'mouseenter', ->
  declineBg.className = 'hover'

decline.addEventListener 'mouseleave', ->
  declineBg.className = ''

decline.addEventListener 'click', ->
  remote.require('app').quit()

#
# Step 1 -- install directory
#

installPath       = document.getElementById 'installPath'
installBrowse     = document.getElementById 'installBrowse'
installContinue   = document.getElementById 'installContinue'
installContinueBg = document.getElementById 'installContinueBg'

steamLaunch       = remote.getCurrentWindow().steamLaunch

if process.platform == 'linux'
  document.getElementById("linux_info").className = ''  # remove .hidden from linux_info

installContinue.addEventListener 'mouseenter', ->
  installContinueBg.className = 'hover'

installContinue.addEventListener 'mouseleave', ->
  installContinueBg.className = ''



# default install dir
installPath.value = localStorage.getItem('installDir') ||
                    path.resolve(path.join(electronApp.getPath('userData'), '..'))

# Try to automatically determine the correct install path
# (as greenworks.getCurrentGameInstallDir() is not yet implemented)
if steamLaunch
  cwd = __dirname.toLowerCase().split(path.sep)

  pos_steamapps = cwd.indexOf("steamapps")
  pos_common    = cwd.indexOf("common")
  pos_starmade  = cwd.indexOf("starmade")

  automatic_path = ""

  console.log("Determining Steam install path...")  ##debug

  # Does the path conform to Steam's standard directory structure?
  # The path should always include "SteamApps/common" somewhere
  if (pos_steamapps>0 && pos_steamapps<pos_common)
    console.log("> SteamApps/common exists")  ##debug
    # with "StarMade" following it
    if (pos_starmade == pos_common + 1)
      console.log("> SteamApps/common immediately preceeds StarMade")  ##debug

      # If so, slice the existing path up to (and including) "StarMade"
      # append another "StarMade" directory for the game to live in, and clean it.
      automatic_path = __dirname.split(path.sep).slice(0, pos_starmade+1).join(path.sep)
      automatic_path = path.normalize( path.join(automatic_path, "StarMade") )
      console.log("| automatic path: #{automatic_path}")  ##debug

    else
      console.log("> StarMade does not exist, or is in an unexpected place")  ##debug
      # No? Someone likely just renamed StarMade to something else, or moved it to a subfolder. (why?)
      # So instead we'll discover the correct directory by working backwards.
      
      # Slice up to and including "app.asar"
      pos_asar = cwd.indexOf("app.asar")

      # This should always happen
      if (pos_asar>0)
        # navigate backwards from "app.asar" to "resources" to the launcher directory
        # append a "StarMade" directory for the game to live in, then condense and clean
        automatic_path  = __dirname.split(path.sep).slice(0, pos_asar+1).join(path.sep)
        automatic_path = path.normalize( path.join(automatic_path, "..", "..", "StarMade") )

        console.log("| automatic path: #{automatic_path}")  ##debug
      else
        # This should never happen. (where exactly is this code running?)
        console.error("Unexpected runtime path: #{__dirname}")
        # Fallback to the default install folder
        console.log("| using fallback path")  ##debug
        automatic_path = installPath.value
  else
    console.log("Steam folder structure not found.")

  if automatic_path != ""
    console.log("> using automatic path")  ##debug

    # Automatically set the path and move onto the next step
    installPath.value = path.resolve( automatic_path )
    step1.style.display = 'none'
    step2.style.display = 'block'
    currentStep = 2

  # automatic path
# steamLaunch


console.log("Install path: #{installPath.value}")  ##debug


installBrowse.addEventListener 'click', ->
  dialog.showOpenDialog remote.getCurrentWindow(),
    title: 'Select Installation Directory'
    properties: ['openDirectory']
    defaultPath: installPath.value
  , (newPath) ->
    return unless newPath?
    newPath = path.join(newPath[0], 'StarMade')  if !newPath[0].endsWith(path.sep + "StarMade")
    installPath.value = newPath

installContinue.addEventListener 'click', ->
  currentStep = 2
  localStorage.setItem 'installDir', installPath.value
  step1.style.display = 'none'
  step2.style.display = 'block'


#
# Step 2
#

next = document.getElementById 'next'
next.addEventListener 'click', ->
  currentStep = 3
  localStorage.setItem 'gotStarted', true
  step2.style.display = 'none'
  step3.style.display = 'block'

#
# Step 3
#

login = document.getElementById 'login'
loginBg = document.getElementById 'loginBg'
createAccount = document.getElementById 'createAccount'
createAccountBg = document.getElementById 'createAccountBg'
skip = document.getElementById 'skip'
skipBg = document.getElementById 'skipBg'

login.addEventListener 'mouseenter', ->
  loginBg.className = 'hover'

login.addEventListener 'mouseleave', ->
  loginBg.className = ''

login.addEventListener 'click', ->
  localStorage.setItem 'authGoto', 'uplink'
  window.close()

createAccount.addEventListener 'mouseenter', ->
  createAccountBg.className = 'hover'

createAccount.addEventListener 'mouseleave', ->
  createAccountBg.className = ''

createAccount.addEventListener 'click', ->
  localStorage.setItem 'authGoto', 'register'
  window.close()

skip.addEventListener 'mouseenter', ->
  skipBg.className = 'hover'

skip.addEventListener 'mouseleave', ->
  skipBg.className = ''

skip.addEventListener 'click', ->
  localStorage.setItem 'authGoto', 'guest'
  window.close()


#
# Step 4
#

link = document.getElementById 'link'
linkBg = document.getElementById 'linkBg'
skipOnce = document.getElementById 'skipOnce'
skipOnceBg = document.getElementById 'skipOnceBg'
skipAlways = document.getElementById 'skipAlways'

link.addEventListener 'mouseenter', ->
  linkBg.className = 'hover'

link.addEventListener 'mouseleave', ->
  linkBg.className = ''

link.addEventListener 'click', ->
  # Steam linking takes place on the Registry website
  shell.openExternal 'https://registry.star-made.org/profile/steam_link'
  window.close()

skipOnce.addEventListener 'mouseenter', ->
  skipOnceBg.className = 'hover'

skipOnce.addEventListener 'mouseleave', ->
  skipOnceBg.className = ''

skipOnce.addEventListener 'click', ->
  window.close()

skipAlways.addEventListener 'click', ->
  localStorage.setItem 'steamLinked', 'ignored'
  window.close()

#
# Footer links
#

licensesLink = document.getElementById 'licensesLink'

licensesLink.addEventListener 'click', ->
  showLicenses()
