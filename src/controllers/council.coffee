'use strict'

app = angular.module 'launcher'

app.controller 'CouncilCtrl', ($http, $scope, $sce) ->
  $http.get 'http://starmadedock.net/forums/council-news/index.rss'
    .then (response) ->
      $scope.news = []

      # Convert the data to the same format that the news page uses
      response.data.rss.channel.item.forEach (item) ->
        $scope.news.push
          title: item.title
          body: item.encoded.toString()
          created_at: new Date(item.pubDate).getTime()

      $scope.news.forEach (entry) ->
        entry.body = $sce.trustAsHtml(entry.body)
    , ->
      if !navigator.onLine
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve council news, you are not connected to the Internet')
        }]
      else
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve council news at this time.')
        }]
