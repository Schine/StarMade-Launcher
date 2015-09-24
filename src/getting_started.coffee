'use strict'

fs = require('fs')
ipc = require('ipc')
path = require('path')
remote = require('remote')
shell = require('shell')

util = require('./util')

close = document.getElementById 'close'
footerLinks = document.getElementById 'footerLinks'
currentStep = -1

step0 = document.getElementById 'step0'
step1 = document.getElementById 'step1'
step2 = document.getElementById 'step2'
step3 = document.getElementById 'step3'
updating = document.getElementById 'updating'

showLicenses = ->
  close.style.display = 'none'
  step0.style.display = 'block'
  step1.style.display = 'none'
  step2.style.display = 'none'
  step3.style.display = 'none'
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

close.addEventListener 'click', ->
  remote.require('app').quit()

if localStorage.getItem('gotStarted')?
  if window.location.href.split('?')[1] == 'licenses'
    showLicenses()
    remote.getCurrentWindow().show()
  else if window.location.href.split('?')[1] == 'steam'
    currentStep = 3
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
# Step 1
#

next = document.getElementById 'next'
next.addEventListener 'click', ->
  currentStep = 2
  localStorage.setItem 'gotStarted', true
  step1.style.display = 'none'
  step2.style.display = 'block'

#
# Step 2
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
# Step 3
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
