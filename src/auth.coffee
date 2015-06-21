'use strict'

REGISTRY_TOKEN_URL = 'https://registry.star-made.org/oauth/token'

ipc = require('ipc')
remote = require('remote')
request = require('request')

util = require('./util')

uplinkLink = document.getElementById 'uplinkLink'
guestLink = document.getElementById 'guestLink'

uplinkForm = document.getElementById 'uplink'
uplinkSubmit = document.getElementById 'uplinkSubmit'
status = document.getElementById 'status'
rememberMe = false
rememberMeLabel = document.getElementById 'rememberMeLabel'
rememberMeBox = document.getElementById 'rememberMe'
registerLink = document.getElementById 'registerLink'

guestForm = document.getElementById 'guest'

registerForm = document.getElementById 'register'
registerBack = document.getElementById 'registerBack'
registerSubmit = document.getElementById 'registerSubmit'
registerSubmitBg = document.getElementById 'registerSubmitBg'
subscribe = true
subscribeLabel = document.getElementById 'subscribeLabel'
subscribeBox = document.getElementById 'subscribe'

licensesLink = document.getElementById 'licensesLink'

originalWidth = window.innerWidth
originalHeight = window.innerHeight

util.setupExternalLinks()

if localStorage.getItem('playerName')?
  # Set username and player name to last used player name
  playerName = localStorage.getItem 'playerName'
  document.getElementById('username').value = playerName
  document.getElementById('playerName').value = playerName

showGuest = ->
  uplinkForm.style.display = 'none'
  guestForm.style.display = 'block'

showRegister = ->
  uplinkForm.style.display = 'none'
  guestForm.style.display = 'none'
  registerForm.style.display = 'block'

  # TODO: May need to account the height offset used in OS X
  remote.getCurrentWindow().setSize(window.innerWidth, 508)
  remote.getCurrentWindow().center()

exitRegister = ->
  uplinkForm.style.display = 'block'
  guestForm.style.display = 'none'
  registerForm.style.display = 'none'

  remote.getCurrentWindow().setSize(originalWidth, originalHeight)
  remote.getCurrentWindow().center()

switch localStorage.getItem('authGoto')
  when 'guest'
    showGuest()
  when 'register'
    showRegister()
localStorage.removeItem('authGoto')

rememberMe = util.parseBoolean localStorage.getItem 'rememberMe'
rememberMeBox.innerHTML = '&#10003;' if rememberMe

uplinkLink.addEventListener 'click', (event) ->
  event.preventDefault()

  uplinkForm.style.display = 'block'
  guestForm.style.display = 'none'

guestLink.addEventListener 'click', (event) ->
  event.preventDefault()

  showGuest()

doLogin = (event) ->
  event.preventDefault()

  status.innerHTML = 'Logging in...'

  request.post REGISTRY_TOKEN_URL,
    form:
      grant_type: 'password'
      username: document.getElementById('username').value,
      password: document.getElementById('password').value,
      scope: 'public read_citizen_info client'
    (err, res, body) ->
      body = JSON.parse body
      if !err && res.statusCode == 200
        ipc.send 'finish-auth', body
      else if res.statusCode == 401
        status.innerHTML = 'Invalid credentials.'
      else
        status.innerHTML = 'Unable to login, please try later.'

uplinkForm.addEventListener 'submit', doLogin
uplinkSubmit.addEventListener 'click', doLogin

toggleRememberMe = ->
  rememberMe = !rememberMe
  localStorage.setItem 'rememberMe', rememberMe
  if rememberMe
    rememberMeBox.innerHTML = '&#10003;'
  else
    rememberMeBox.innerHTML = '&nbsp;'

rememberMeLabel.addEventListener 'click', toggleRememberMe
rememberMeBox.addEventListener 'click', toggleRememberMe
registerLink.addEventListener 'click', showRegister

doGuest = (event) ->
  event.preventDefault()

  ipc.send 'finish-auth',
    playerName: document.getElementById('playerName').value

guestForm.addEventListener 'submit', doGuest
guestSubmit.addEventListener 'click', doGuest

doRegister = (event) ->
  event.preventDefault()

  # TODO: Implement registration
  status.innerHTML = 'Registered! Please confirm your email.'
  exitRegister()

registerForm.addEventListener 'submit', doRegister
registerSubmit.addEventListener 'click', doRegister

registerBack.addEventListener 'click', (event) ->
  event.preventDefault()

  exitRegister()

registerSubmit.addEventListener 'mouseenter', ->
  registerSubmitBg.className = 'hover'

registerSubmit.addEventListener 'mouseleave', ->
  registerSubmitBg.className = ''

toggleSubscribe = ->
  subscribe = !subscribe
  if subscribe
    subscribeBox.innerHTML = '&#10003;'
  else
    subscribeBox.innerHTML = '&nbsp;'

subscribeLabel.addEventListener 'click', toggleSubscribe
subscribeBox.addEventListener 'click', toggleSubscribe

licensesLink.addEventListener 'click', (event) ->
  event.preventDefault()

  ipc.send 'open-licenses'
