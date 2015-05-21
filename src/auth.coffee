'use strict'

REGISTRY_TOKEN_URL = 'https://registry.star-made.org/oauth/token'

ipc = require('ipc')
request = require('request')
shell = require('shell')

externalLinks = document.getElementsByClassName 'external'
uplinkForm = document.getElementById 'uplink'
guestForm = document.getElementById 'guest'

if localStorage.getItem('playerName')?
  # Set username and player name to last used player name
  playerName = localStorage.getItem 'playerName'
  document.getElementById('username').value = playerName
  document.getElementById('playerName').value = playerName

Array.prototype.forEach.call externalLinks, (link) ->
  link.addEventListener 'click', (event) ->
    event.preventDefault()

    shell.openExternal this.href

uplinkForm.addEventListener 'submit', (event) ->
  event.preventDefault()

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
      else
        document.getElementById('error').innerHTML =
          'Sorry, your username or password was incorrect'

guestForm.addEventListener 'submit', (event) ->
  event.preventDefault()

  ipc.send 'finish-auth',
    playerName: document.getElementById('playerName').value
