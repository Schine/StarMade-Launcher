'use strict'

app = angular.module 'launcher'

app.controller 'NewsCtrl', ($http, $scope, $rootScope, $sce, NewsSidebarEntry) ->
  $http.get 'https://star-made.org/news.json'
    .then (response) ->
      $rootScope.log.event "Retrieved news"

      $scope.news = response.data
      $scope.news.forEach (entry) ->
        entry.body = entry.body.replace(/style=['"].*?["']/g, '')
        entry.body = $sce.trustAsHtml(entry.body)
    .catch (response) ->
      if !navigator.onLine
        $rootScope.log.warning "Unable to retrieve news (no internet connection)"
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news, you are not connected to the Internet')
        }]
      else
        $rootScope.log.error "Unable to retrieve news (unknown cause)"
        $rootScope.log.error response
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news at this time.')
        }]

  $scope.sidebarEntries = NewsSidebarEntry.query()
