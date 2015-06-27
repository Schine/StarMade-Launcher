'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'NewsCtrl', ($http, $scope, $sce) ->
  $http.get 'https://star-made.org/news.json'
    .success (data) ->
      $scope.news = data
      $scope.news.forEach (entry) ->
        entry.body = entry.body.replace(/style=['"].*["']/g, '')
        entry.body = $sce.trustAsHtml(entry.body)
    .error ->
      if !navigator.onLine
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news, you are not connected to the Internet')
        }]
      else
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news at this time.')
        }]
