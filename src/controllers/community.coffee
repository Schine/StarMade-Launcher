'use strict'

app = angular.module 'launcher'

app.controller 'CommunityCtrl', ($scope, CommunityContentEntry) ->
  contentEntries = CommunityContentEntry.query ->
    selected = []

    for [1..4]
      entryIndex = Math.floor(Math.random() * contentEntries.length) until selected.indexOf(entryIndex) == -1 && contentEntries[entryIndex]?
      selected.push contentEntries[entryIndex]

    $scope.contentEntries = selected
    $scope.featured = $scope.contentEntries[0]
    $scope.featuredRating = parseFloat($scope.featured.community_content_entry.rating)
  , (err) ->
    console.log err
