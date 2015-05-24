'use strict'

REGISTRY_TOKEN_URL = 'https://registry.star-made.org/oauth/token'

ipc = require('ipc')
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

guestForm = document.getElementById 'guest'

util.setupExternalLinks()

if localStorage.getItem('playerName')?
  # Set username and player name to last used player name
  playerName = localStorage.getItem 'playerName'
  document.getElementById('username').value = playerName
  document.getElementById('playerName').value = playerName

rememberMe = util.parseBoolean localStorage.getItem 'rememberMe'
rememberMeBox.innerHTML = '&#10003;' if rememberMe

uplinkLink.addEventListener 'click', (event) ->
  event.preventDefault()

  uplinkForm.style.display = 'block'
  guestForm.style.display = 'none'

guestLink.addEventListener 'click', (event) ->
  event.preventDefault()

  uplinkForm.style.display = 'none'
  guestForm.style.display = 'block'

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

doGuest = (event) ->
  event.preventDefault()

  ipc.send 'finish-auth',
    playerName: document.getElementById('playerName').value

guestForm.addEventListener 'submit', doGuest
guestSubmit.addEventListener 'click', doGuest
