'use strict'

remote = require('remote')
shell = require('shell')

util = require('./util')

step1 = document.getElementById 'step1'
step2 = document.getElementById 'step2'
step3 = document.getElementById 'step3'

if localStorage.getItem('gotStarted')?
  if window.location.href.split('?')[1] == 'steam'
    step1.style.display = 'none'
    step3.style.display = 'block'
    remote.getCurrentWindow().show()
  else
    window.close()
    return
else
  remote.getCurrentWindow().show()

localStorage.setItem 'gotStarted', true

util.setupExternalLinks()

#
# Step 1
#

next = document.getElementById 'next'
next.addEventListener 'click', ->
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
  # TODO: Confirm with user that they are linking to the right Steam account
  # TODO: Link the account
  localStorage.setItem 'steamLinked', true
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
