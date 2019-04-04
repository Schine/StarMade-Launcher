'use strict'

REGISTRY_TOKEN_URL = 'https://registry.star-made.org/oauth/token'
REGISTRY_REGISTER_URL = 'https://registry.star-made.org/api/v1/users.json'

electron = require('electron')
request  = require('request')

ipc    = electron.ipcRenderer
remote = electron.remote

util    = require('./util')
log     = require('./log-helpers')


close = document.getElementById 'close'

uplinkLink = document.getElementById 'uplinkLink'
guestLink = document.getElementById 'guestLink'

uplinkForm = document.getElementById 'uplink'
uplinkSubmit = document.getElementById 'uplinkSubmit'
status = document.getElementById 'status'
statusGuest = document.getElementById 'statusGuest'
rememberMe = false
rememberMeLabel = document.getElementById 'rememberMeLabel'
rememberMeBox = document.getElementById 'rememberMe'
registerLink = document.getElementById 'registerLink'

guestForm = document.getElementById 'guest'

registerForm = document.getElementById 'register'
registerBack = document.getElementById 'registerBack'
registerSubmit = document.getElementById 'registerSubmit'
registerSubmitBg = document.getElementById 'registerSubmitBg'
registerStatus = document.getElementById 'registerStatus'
subscribe = true
subscribeLabel = document.getElementById 'subscribeLabel'
subscribeBox = document.getElementById 'subscribe'

licensesLink = document.getElementById 'licensesLink'

originalWidth = window.innerWidth
originalHeight = window.innerHeight

util.setupExternalLinks()

close.addEventListener 'click', ->
  remote.app.quit()

if localStorage.getItem('playerName')?
  # Set username and player name to last used player name
  playerName = localStorage.getItem 'playerName'
  document.getElementById('username').value = playerName
  document.getElementById('playerName').value = playerName

showGuest = ->
  uplinkForm.style.display = 'none'
  guestForm.style.display = 'block'

showRegister = ->
  close.style.display = 'none'
  uplinkForm.style.display = 'none'
  guestForm.style.display = 'none'
  registerForm.style.display = 'block'

  # TODO: May need to account the height offset used in OS X
  remote.getCurrentWindow().setSize(window.innerWidth, 508)
  remote.getCurrentWindow().center()

exitRegister = ->
  close.style.display = 'inline'
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
rememberMeBox.innerHTML = '&#x2713;' if rememberMe

uplinkLink.addEventListener 'click', (event) ->
  event.preventDefault()

  uplinkForm.style.display = 'block'
  guestForm.style.display = 'none'

guestLink.addEventListener 'click', (event) ->
  event.preventDefault()

  showGuest()

doLogin = (event) ->
  event.preventDefault()

  unless navigator.onLine
    status.innerHTML = 'You are not connected to the Internet.'
    return

  status.innerHTML = 'Logging in...'

  request.post REGISTRY_TOKEN_URL,
    form:
      grant_type: 'password'
      username: document.getElementById('username').value.trim(),
      password: document.getElementById('password').value,
      scope: 'public read_citizen_info client'
    (err, res, body) ->
      body = JSON.parse body
      if !err && res.statusCode == 200
        log.entry "Logged in as #{document.getElementById('username').value.trim()}"
        ipc.send 'finish-auth', body
      else if res.statusCode == 401
        log.entry "Invalid login credentials"
        status.innerHTML = 'Invalid credentials.'
      else
        log.entry "Unable to log in (#{res.statusCode})"
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

  playerName = document.getElementById('playerName').value.trim()
  unless !!playerName && playerName.length >= 3
    statusGuest.innerHTML = "Invalid username"
    return

  log.entry "Guest login: #{playerName}"
  ipc.send 'finish-auth',
    playerName: playerName

guestForm.addEventListener 'submit', doGuest
guestSubmit.addEventListener 'click', doGuest

doRegister = (event) ->
  event.preventDefault()

  registerStatus.innerHTML = 'Registering...'

  username = document.getElementById('registerUsername').value

  request.post REGISTRY_REGISTER_URL,
    form:
      user:
        username: document.getElementById('registerUsername').value,
        email: document.getElementById('registerEmail').value,
        password: document.getElementById('registerPassword').value,
        password_confirmation: document.getElementById('registerPassword').value,
        subscribe_to_newsletter: if subscribe then '1' else '0'
    (err, res, body) ->
      body = JSON.parse body
      if !err && (res.statusCode == 200 || res.statusCode == 201)
        registerStatus.innerHTML = ''
        log.entry "Registered new account"
        status.innerHTML = 'Registered! Please confirm your email.'
        document.getElementById('username').value = username
        exitRegister()
      else if res.statusCode == 422
        field = Object.keys(body.errors)[0]
        error = body.errors[field][0]
        field = field.substring(0, 1).toUpperCase() + field.substring(1, field.length)

        log.error "Error registering account"
        log.indent.entry "#{field} #{error}"
        registerStatus.innerHTML = "#{field} #{error}"
      else
        log.warning "Unable to register account (#{res.statusCode})"
        registerStatus.innerHTML = 'Unable to register, please try later.'

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
