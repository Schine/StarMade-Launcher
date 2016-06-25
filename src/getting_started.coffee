'use strict'

fs = require('fs')
ipc = require('ipc')
path = require('path')
remote = require('remote')
dialog = remote.require('dialog')
electronApp = remote.require('app')
shell = require('shell')

util = require('./util')

steamLaunch = remote.getCurrentWindow().steamLaunch

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
  console.log(" > showLicenses()")  ##~
  close.style.display = 'none'
  step0.style.display = 'block'
  step1.style.display = 'none'
  step2.style.display = 'none'
  step3.style.display = 'none'
  step4.style.display = 'none'
  updating.style.display = 'none'
  footerLinks.style.display = 'none'
  console.log("   | currentStep: #{currentStep}")  ##~
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~


showUpdating = ->
  console.log(" > showUpdating()")  ##~
  step0.style.display = 'none'
  updating.style.display = 'block'
  console.log("   | currentStep: #{currentStep}")  ##~
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~


determineInstallDirectory = ->
  # Try to automatically determine the correct install path
  console.log(" > determineInstallDirectory()")  ##~
  cwd            = __dirname.toLowerCase().split(path.sep)
  pos_asar       = cwd.indexOf("app.asar")
  pos_steamapps  = cwd.indexOf("steamapps")
  pos_common     = cwd.indexOf("common")
  pos_starmade   = cwd.indexOf("starmade")
  suggested_path = ""

  install_automatically = false

  if (pos_asar>0)
    # navigate backwards from "app.asar" to "resources" to the launcher directory
    # append a "StarMade" directory for the game to live in, then condense and clean
    suggested_path = __dirname.split(path.sep).slice(0, pos_asar+1).join(path.sep)
    suggested_path = path.normalize( path.join(suggested_path, "..", "..", "StarMade") )

    console.log("   | Suggested path: #{suggested_path}")  ##~
  else
    # This should never happen. (is __dirname not supported?)
    console.error("Error: Unexpected runtime path: #{__dirname}.  Using fallback.")
    # Fallback to the default install folder
    suggested_path = default_install_path
    console.log("   | Suggesting fallback path (#{default_install_path})")  ##~




  # Automatically use the suggested path for steam installs
  # (determine manually as greenworks.getCurrentGameInstallDir() is not yet implemented)
  console.log("   > Checking for Steam folder structure")  ##~


  # Does the path conform to Steam's standard directory structure?
  # The path should always include "SteamApps/common" somewhere
  if (pos_steamapps>0 && pos_steamapps<pos_common)
    console.log("   > SteamApps/common exists")  ##~
    # with "StarMade" following it
    if (pos_starmade == pos_common + 1)
      console.log("   > SteamApps/common immediately preceeds StarMade")  ##~
      install_automatically = true
      console.log("   | install automatically? #{install_automatically}")  ##~
    else
      console.log("    > StarMade does not exist, or is in an unexpected place")  ##~
      # No? Someone likely just renamed StarMade to something else, or moved it to a subfolder. (why? who knows.)
  else
    console.log("    | Steam folder structure not found.")  ##~



  installPath.value = path.resolve( suggested_path )
  console.log("  | Suggested install path: #{installPath.value}")  ##~


  return if !install_automatically
  console.log("  > installing automatically")  ##~

  # Automatically set the path and move onto the next step
  localStorage.setItem 'installDir', installPath.value
  currentStep = 2
  step1.style.display = 'none'
  step2.style.display = 'block'
  console.log(" > Step 2")  ##~
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~


acceptEula = ->
  console.log(" > acceptEula()")  ##~
  console.log("   | currentStep: #{currentStep}")  ##~
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~

  localStorage.setItem 'acceptedEula', true
  close.style.display = 'inline'
  footerLinks.style.display = 'block'

  console.log("   > currentStep switch")  ##~
  switch currentStep
    when -1
      window.close()
    when 0, 1
      currentStep = 1
      console.log("     | currentStep: #{currentStep}")
      step0.style.display = 'none'
      step1.style.display = 'block'
      determineInstallDirectory()
    when 2
      step0.style.display = 'none'
      step2.style.display = 'block'
    when 3
      step0.style.display = 'none'
      step3.style.display = 'block'
    when 4
      step0.style.display = 'none'
      step4.style.display = 'block'
  console.log("   > currentStep switch -- after")  ##~
  console.log("   | currentStep: #{currentStep}")  ##~  
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~


close.addEventListener 'click', ->
  remote.require('app').quit()

console.log("[Root]")  ##~
console.log(" | localStorage: #{JSON.stringify(localStorage)}")  ##~
unless localStorage.getItem('gotStarted')?
  # If the user has not finished the initial setup, restart it and present the EULA again.
  console.log(" ! User did not finish previous setup; restarting")
  localStorage.removeItem('acceptedEula')
  # This also prevents a race condition between a) showing the window and b) updating the install directory textbox
  # -- The events required to solve this race condition [getCurrentWindow.on('show' / 'ready-to-show')] currently do not fire.
console.log(" | currentStep: #{currentStep}")  ##~
console.log(" | step0: #{step0.style.display}")  ##~
console.log(" | step1: #{step1.style.display}")  ##~
console.log(" | step2: #{step2.style.display}")  ##~
console.log(" | step3: #{step3.style.display}")  ##~
console.log(" | step4: #{step4.style.display}")  ##~
console.log(" | window.location.href: #{window.location.href}")  ##~

console.log(" > State block")  ##~
if localStorage.getItem('gotStarted')?
  if window.location.href.split('?')[1] == 'licenses'
    showLicenses()
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'steam'
    currentStep = 4
    step0.style.display = 'none'
    step3.style.display = 'block'
    footerLinks.style.display = 'block'
    console.log(" > Step 4 -- Steam")  ##~
    console.log("   | step0: #{step0.style.display}")  ##~
    console.log("   | step1: #{step1.style.display}")  ##~
    console.log("   | step2: #{step2.style.display}")  ##~
    console.log("   | step3: #{step3.style.display}")  ##~
    console.log("   | step4: #{step4.style.display}")  ##~
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'updating'
    showUpdating()
    ipc.send('updating-opened')
    remote.getCurrentWindow().show()
  else
    window.close()
    return
else
  console.log(" > State block -- else")
  console.log("   | currentStep: 0")
  currentStep = 0
  acceptEula() if localStorage.getItem('acceptedEula')?
  remote.getCurrentWindow().show()

util.setupExternalLinks()

console.log(" > State block -- after")  ##~
console.log(" | window.location.href: #{window.location.href}")  ##~
console.log(" | currentStep: #{currentStep}")  ##~


#
# Step 0 (Licenses)
#

console.log("--- root-level code ---")
console.log(" > Step 0 -- Licenses")  ##~
console.log("   | step0: #{step0.style.display}")  ##~
console.log("   | step1: #{step1.style.display}")  ##~
console.log("   | step2: #{step2.style.display}")  ##~
console.log("   | step3: #{step3.style.display}")  ##~
console.log("   | step4: #{step4.style.display}")  ##~
console.log("--- end root-level code ---")

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


# default install dir
default_install_path = localStorage.getItem('installDir') ||
                       path.resolve(path.join(electronApp.getPath('userData'), '..'))
installPath.value    = default_install_path


if process.platform == 'linux'
  document.getElementById("linux_info").className = ''  # remove .hidden from linux_info

installContinue.addEventListener 'mouseenter', ->
  installContinueBg.className = 'hover'

installContinue.addEventListener 'mouseleave', ->
  installContinueBg.className = ''

installBrowse.addEventListener 'click', ->
  dialog.showOpenDialog remote.getCurrentWindow(),
    title: 'Select Installation Directory'
    properties: ['openDirectory']
    defaultPath: installPath.value
  , (newPath) ->
    return unless newPath?
    newPath = path.join(newPath[0], 'StarMade')  if !(newPath[0].endsWith(path.sep + "StarMade")
    installPath.value = newPath

installContinue.addEventListener 'click', ->
  console.log("> using manual path (#{installPath.value})")  ##~
  currentStep = 2
  localStorage.setItem 'installDir', installPath.value
  step1.style.display = 'none'
  step2.style.display = 'block'
  console.log(" > Step 2")  ##~
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~




#
# Step 2
#

next = document.getElementById 'next'
next.addEventListener 'click', ->
  currentStep = 3
  localStorage.setItem 'gotStarted', true
  step2.style.display = 'none'
  step3.style.display = 'block'

  console.log(" > Step 3 -- Account")
  console.log("   | step0: #{step0.style.display}")  ##~
  console.log("   | step1: #{step1.style.display}")  ##~
  console.log("   | step2: #{step2.style.display}")  ##~
  console.log("   | step3: #{step3.style.display}")  ##~
  console.log("   | step4: #{step4.style.display}")  ##~


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
