'use strict'

app = angular.module 'launcher'

app.factory 'citizenBroadcastApi', ($http, apiConfig, $rootScope) ->
  @get = ->
    $http.get("https://#{apiConfig.baseUrl}/api/v1/citizen_broadcasts.json")
      .then (response) ->

          $rootScope.log.event "Checking for citizen broadcasts"

          # Get last-displayed broadcast ID
          last_id = localStorage.getItem('last_broadcast_id') || -1

          # Fetch and combine all broadcasts
          messages   = []
          broadcasts = response.data
          broadcasts.forEach (broadcast) ->
            broadcast = broadcast.citizen_broadcast

            # Only display broadcasts once
            if broadcast.id > last_id
              localStorage.setItem('last_broadcast_id', broadcast.id)
              $rootScope.log.indent.entry "Displaying broadcast ##{broadcast.id}"
            else
              $rootScope.log.indent.verbose "Already displayed broadcast ##{broadcast.id}"
              return

            message   = ""
            message  += broadcast.message
            message  += "\r\n\r\n"
            messages.push message
            messages.push "<hr/>"


          # No broadcasts to display?
          return null  if messages.length == 0

          # Remove trailing <hr/> and join into a single string
          messages.pop()
          message = messages.join("")
          # Convert newlines to markup
          message = message.split("\r\n").join("<br/>")

          $rootScope.log.indent.verbose "markup: #{message}"
          return message


        , (err) ->
          msg = (err.message || err || "(unknown error)")
          $rootScope.log.error "Error fetching citizen broadcasts: #{msg}"
          return null

  return this