'use strict'

fs     = require('fs')
ipc    = require('ipc')
path   = require('path')
shell  = require('shell')
remote = require('remote')

util   = require('./util')

dialog      = remote.require('dialog')
electronApp = remote.require('app')

steamLaunch = remote.getCurrentWindow().steamLaunch

close       = document.getElementById 'close'
footerLinks = document.getElementById 'footerLinks'
currentStep = -1


step0 = document.getElementById 'step0'
step1 = document.getElementById 'step1'
step2 = document.getElementById 'step2'
step3 = document.getElementById 'step3'
step4 = document.getElementById 'step4'
updating = document.getElementById 'updating'


#TODO: write a logger and migrate some of the debugging output

showLicenses = ->
  # console.log(" > showLicenses()")  ##~
  close.style.display = 'none'
  step0.style.display = 'block'
  step1.style.display = 'none'
  step2.style.display = 'none'
  step3.style.display = 'none'
  step4.style.display = 'none'
  updating.style.display = 'none'
  footerLinks.style.display = 'none'


showUpdating = ->
  # console.log(" > showUpdating()")  ##~
  step0.style.display    = 'none'
  updating.style.display = 'block'


determineInstallDirectory = ->
  # Try to automatically determine the correct install path
  # console.log(" > determineInstallDirectory()")  ##~

  # Get current working directory from the main process
  cwd            = ipc.sendSync('cwd')
  cwd_array      = cwd.toLowerCase().split(path.sep)
  pos_steamapps  = cwd_array.indexOf("steamapps")
  pos_common     = cwd_array.indexOf("common")
  pos_starmade   = cwd_array.indexOf("starmade")
  suggested_path = ""

  # append a "StarMade" directory for the game to live in, then condense and clean
  suggested_path = path.resolve( path.normalize( path.join(cwd, "StarMade") ) )


  # Automatically use the suggested path for steam installs
  # (determine manually as greenworks.getCurrentGameInstallDir() is not yet implemented)


  # Does the path conform to Steam's standard directory structure?
  # The path should always include "SteamApps/common" somewhere
  install_automatically = false
  if (pos_steamapps>0 && pos_steamapps<pos_common)
    # with "StarMade" following it
    if (pos_starmade == pos_common + 1)
      # console.log("   | Correct steam path found")  ##~
      install_automatically = true
    # Otherwise, Someone likely just renamed StarMade to something else, or moved it to a subfolder. (why? who knows.)



  installPath.value = path.resolve( suggested_path )
  # console.log("  | Suggested install path: #{installPath.value}")  ##~


  return if !install_automatically
  # console.log("  > installing automatically")  ##~

  # Automatically set the path and move onto the next step
  localStorage.setItem 'installDir', installPath.value
  currentStep = 2
  step1.style.display = 'none'
  step2.style.display = 'block'
  # console.log(" > Step 2")  ##~
  

acceptEula = ->
  # console.log(" > acceptEula()")  ##~
  # console.log("   | currentStep: #{currentStep}")  ##~
  
  localStorage.setItem 'acceptedEula', true
  close.style.display = 'inline'
  footerLinks.style.display = 'block'

  # console.log("   > currentStep switch")  ##~
  switch currentStep
    when -1
      window.close()
    when 0, 1
      currentStep = 1
      # console.log("     | currentStep: #{currentStep}")  ##~
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
  # console.log("   > currentStep switch -- after")  ##~
  # console.log("   | currentStep: #{currentStep}")  ##~  


close.addEventListener 'click', ->
  remote.require('app').quit()

# console.log("[Root]")  ##~
# console.log(" | localStorage: #{JSON.stringify(localStorage)}")  ##~
unless localStorage.getItem('gotStarted')?
  # If the user has not finished the initial setup, restart it and present the EULA again.
  # console.log(" ! User did not finish previous setup; restarting")  ##~
  localStorage.removeItem('acceptedEula')
  # This also prevents a race condition between a) showing the window and b) updating the install directory textbox
  # -- The events required to solve this race condition [getCurrentWindow.on('show' / 'ready-to-show')] currently do not fire.

# console.log(" | currentStep: #{currentStep}")  ##~
# console.log(" | window.location.href: #{window.location.href}")  ##~

# console.log(" > State block")  ##~
if localStorage.getItem('gotStarted')?
  if window.location.href.split('?')[1] == 'licenses'
    showLicenses()
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'steam'
    currentStep = 4
    step0.style.display = 'none'
    step3.style.display = 'block'
    footerLinks.style.display = 'block'
    # console.log(" > Step 4 -- Steam")  ##~
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'updating'
    showUpdating()
    ipc.send('updating-opened')
    remote.getCurrentWindow().show()
  else
    window.close()
    return
else
  # console.log(" > State block -- else")  ##~
  # console.log("   | currentStep: 0")  ##~
  currentStep = 0
  acceptEula() if localStorage.getItem('acceptedEula')?
  remote.getCurrentWindow().show()

util.setupExternalLinks()

# console.log(" > State block -- after")  ##~
# console.log(" | window.location.href: #{window.location.href}")  ##~
# console.log(" | currentStep: #{currentStep}")  ##~


#
# Step 0 (Licenses)
#

# console.log(" > Step 0 -- Licenses")  ##~

licenses  = document.getElementById 'licenses'
accept    = document.getElementById 'accept'
acceptBg  = document.getElementById 'acceptBg'
decline   = document.getElementById 'decline'
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
    newPath = newPath[0]

    # Scenario: existing install
    if fs.existsSync( path.join(newPath, "StarMade.jar") )
      # console.log "installBrowse(): Found StarMade.jar here:  #{path.join(newPath, "StarMade.jar")}"
      installPath.value = newPath
      return

    # Scenario: StarMade/StarMade
    if (path.basename(             newPath.toLowerCase())  == "starmade" &&
        path.basename(path.dirname(newPath.toLowerCase())) == "starmade" )  # ridiculous, but functional
      # console.log "installBrowse(): Path ends in StarMade/StarMade  (path: #{newPath})"
      installPath.value = newPath
      return

    # Default: append StarMade
    installPath.value = path.join(newPath, 'StarMade')
    # console.log "installBrowse(): installing to #{installPath.value}"


installContinue.addEventListener 'click', ->
  # console.log("> using manual path (#{installPath.value})")  ##~
  currentStep = 2
  localStorage.setItem 'installDir', installPath.value
  step1.style.display = 'none'
  step2.style.display = 'block'
  # console.log(" > Step 2")  ##~



#
# Step 2
#

next = document.getElementById 'next'
next.addEventListener 'click', ->
  currentStep = 3
  localStorage.setItem 'gotStarted', true
  step2.style.display = 'none'
  step3.style.display = 'block'
  # console.log(" > Step 3 -- Account")  ##~



#
# Step 3
#


login           = document.getElementById 'login'
loginBg         = document.getElementById 'loginBg'
createAccount   = document.getElementById 'createAccount'
createAccountBg = document.getElementById 'createAccountBg'
skip            = document.getElementById 'skip'
skipBg          = document.getElementById 'skipBg'

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


link       = document.getElementById 'link'
linkBg     = document.getElementById 'linkBg'
skipOnce   = document.getElementById 'skipOnce'
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
