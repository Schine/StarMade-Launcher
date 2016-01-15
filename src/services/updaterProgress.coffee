'use strict'

app = angular.module 'launcher'

app.service 'updaterProgress', ($rootScope) ->
  @text = ''

  @curValue = 0
  @maxValue = 100

  @filesDone = 0
  @filesCount = 0

  @inProgress = false

  @calculatePercentage = ->
    Math.round @curValue / @maxValue * 100.0

  @toMegabytes = (value) ->
    (value / 1024 / 1024).toFixed 1

  @updateText = ->
    @text = "Downloading files... #{@filesDone}/#{@filesCount} (#{@toMegabytes(@curValue)}MB/#{@toMegabytes(@maxValue)} MB) [#{@calculatePercentage()}%]"

    # Trick to get the progress bar to update quicker
    $rootScope.$digest() unless $rootScope.$$phase

  return
