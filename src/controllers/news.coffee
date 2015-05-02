'use strict'

angular = require('angular')

app = angular.module 'launcher'

app.controller 'NewsCtrl', ($http, $scope, $sce) ->
  $http.get 'https://star-made.org/news.json'
    .success (data) ->
      $scope.news = data
      $scope.news.forEach (entry) ->
        entry.body = $sce.trustAsHtml(entry.body)
