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
createAccount = document.getElementById 'createAccount'
skip = document.getElementById 'skip'

login.addEventListener 'click', ->
  window.close()

createAccount.addEventListener 'click', ->
  # TODO: Introduce a create account dialog instead
  shell.openExternal 'https://registry.star-made.org/users/sign_up'
  window.close()

skip.addEventListener 'click', ->
  # TODO: Go directly to the guest tab on the login dialog
  window.close()
