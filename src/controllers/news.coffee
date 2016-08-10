'use strict'

app = angular.module 'launcher'

app.controller 'NewsCtrl', ($http, $scope, $rootScope, $sce, NewsSidebarEntry) ->
  $http.get 'https://star-made.org/news.json'
    .success (data) ->
      $rootScope.log.event "Retrieved news"

      $scope.news = data
      $scope.news.forEach (entry) ->
        entry.body = entry.body.replace(/style=['"].*["']/g, '')
        entry.body = $sce.trustAsHtml(entry.body)
    .error ->
      if !navigator.onLine
        $rootScope.log.warning "Unable to retrieve news (no internet connection)"
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news, you are not connected to the Internet')
        }]
      else
        $rootScope.log.error "Unable to retrieve news (unknown cause)"
        $scope.news = [{
          body: $sce.trustAsHtml('Unable to retrieve news at this time.')
        }]

  $scope.sidebarEntries = NewsSidebarEntry.query()
