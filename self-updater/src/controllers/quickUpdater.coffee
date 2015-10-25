path = require('path')
remote = require('remote')

app = angular.module 'launcher-self-updater'

app.controller 'QuickUpdaterCtrl', ($filter, $scope, updater, updaterProgress) ->
  argv = remote.getGlobal('argv')
  # TODO: Retrieve the install directory to update
  installDir = path.resolve '../test' #argv.installDir

  $scope.updaterProgress = updaterProgress

  $scope.$watch 'updaterProgress.text', (newVal) ->
    # TODO: Update the progress bar
    console.log newVal

  updater.getVersions 'launcher'
    .then (versions) ->
      versions = $filter('orderBy')(versions, '-build')
      console.log versions
      updater.update versions[0], installDir
