'use strict'

remote = require('remote')
shell = require('shell')

util = require('./util')

if localStorage.getItem('gotStarted')?
  window.close()
  return
else
  remote.getCurrentWindow().show()

localStorage.setItem 'gotStarted', true

util.setupExternalLinks()

step1 = document.getElementById 'step1'
step2 = document.getElementById 'step2'

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
  window.close()

createAccount.addEventListener 'mouseenter', ->
  createAccountBg.className = 'hover'

createAccount.addEventListener 'mouseleave', ->
  createAccountBg.className = ''

createAccount.addEventListener 'click', ->
  # TODO: Introduce a create account dialog instead
  shell.openExternal 'https://registry.star-made.org/users/sign_up'
  window.close()

skip.addEventListener 'mouseenter', ->
  skipBg.className = 'hover'

skip.addEventListener 'mouseleave', ->
  skipBg.className = ''

skip.addEventListener 'click', ->
  # TODO: Go directly to the guest tab on the login dialog
  window.close()
