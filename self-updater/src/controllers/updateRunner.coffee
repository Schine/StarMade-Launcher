path = require('path')
remote = require('electron').remote
_ = require 'underscore'

app = angular.module 'launcher-self-updater'

app.controller 'UpdateRunnerCtrl', ($scope, $element, $http, versionService) ->

  window.scope = $scope

  $scope.status = "Downloading manifest..."

  $scope.progress = 1

  $scope.$watch 'progress', (newVal, oldVal) ->
    document.getElementsByTagName('progress')[0].value = newVal

  $scope.args = remote.getGlobal 'argv'

  $scope.title = -> "Updating Launcher to #{$scope.args.version}"

  $scope.startUpdate = ->
    $scope.status = "Starting Update"
    $scope.progress = 20
    $scope.availableVersions = []

    versionService.getManifestForVersion($scope.args.version).then (manifest) ->


    versionService.getVersions().then (obj) ->
      $scope.availableVersions = obj.data
      latest = _.filter $scope.availableVersions, (ver) -> ver.version
      $scope.status = "Latest version is #{latest.version}, downloading binary..."

