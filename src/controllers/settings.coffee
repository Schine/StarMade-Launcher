'use strict'

os         = require('os')
fs         = require('fs')
path       = require('path')
spawn      = require('child_process').spawn
remote     = require('remote')

dialog     = remote.require('dialog')

util       = require('../util')
pkg        = require('../../package.json')

javaVersion      = pkg.javaVersion
javaJreDirectory = util.getJreDirectory javaVersion

app = angular.module 'launcher'

app.directive 'stringToNumber', ->
  {
    require: 'ngModel'
    link: (scope, element, attrs, ngModel) ->
      ngModel.$parsers.push (value) ->
        '' + value
      ngModel.$formatters.push (value) ->
        parseFloat value, 10
      return
  }


app.controller 'SettingsCtrl', ($scope, $rootScope, accessToken, settings) ->

  # Store the dialog object for 2-way binding of dialog visibility
  $scope.dialog  = settings.dialog

  # Set up available panes
  $scope.availablePanes = ["launcher","memory"]  # install, build, about
  $scope.panes = {}
  for pane in $scope.availablePanes
    $scope.panes[pane] =
      name:    pane
      active:  false
      load:    () -> $rootScope.log.error "Settings: #{pane} pane's load function is not yet defined."
      save:    () -> $rootScope.log.error "Settings: #{pane} pane's save function is not yet defined."



  # Set default pane
  $scope.currentPane = $scope.availablePanes[0]


  # Switch panes
  $scope.$watch 'dialog.pane', (pane) ->
    return  if not pane?
    $rootScope.log.debug "(SetingsCtrl) New settings.dialog.pane: #{pane}"

    if not $scope.availablePanes.indexOf(pane)
      $rootScope.log.debug "$rootScope.openSettings specifies an invalid settings pane (#{pane})"
      return
    # handle opening the pane
    show pane



  $scope.$watch 'currentPane', (pane) ->
    return  if not pane?
    if not $scope.availablePanes.indexOf(pane)
      $rootScope.log.debug "$scope.currentPane specifies an invalid settings pane (#{pane})"
      return
    # Handle opening settings panes here
    show pane


  # Load and show a specific pane, hiding the rest
  show = (pane) ->
    $scope.panes[each_pane].active = false  for each_pane in $scope.availablePanes
    $scope.panes[     pane].active = true
    $scope.panes[     pane].load()
    settings.dialog.show()




  ### Per-pane functions ###



  # --- Memory ---


  # Load memory settings from storage, or set the defaults
  $scope.panes.memory.load = () ->
    _do_logging = false
    if not $rootScope.alreadyExecuted 'Loading memory settings', 1000
      $rootScope.log.event "Loading memory settings"
      _do_logging = true

    # Cap max memory to physical ram
    _max = Number(localStorage.getItem('maxMemory')) || Number(defaults[os.arch()].max)
    $rootScope.log.indent.info "Max memory capped to physical ram"  if _max > defaults[os.arch()].ceiling && _do_logging
    _max = Math.min( _max, defaults[os.arch()].ceiling )


    $scope.panes.memory.max       = _max
    $scope.panes.memory.initial   = Number(localStorage.getItem('initialMemory'))  || Number(defaults[os.arch()].initial)
    $scope.panes.memory.earlyGen  = Number(localStorage.getItem('earlyGenMemory')) || Number(defaults[os.arch()].earlyGen)
    $scope.panes.memory.ceiling   = Number( defaults[os.arch()].ceiling )
    $scope.panes.memory.step      = 256  # Used by #maxMemoryInput.  See AngularJS workaround in $scope.closeClientOptions() below for why this isn't hardcoded.
    $scope.panes.memory.validate  = {}   # Validation checks reside here

    if _do_logging
      $rootScope.log.indent.entry "maxMemory:      #{$scope.memory.max}"
      $rootScope.log.indent.entry "initialMemory:  #{$scope.memory.initial}"
      $rootScope.log.indent.entry "earlyGenMemory: #{$scope.memory.earlyGen}"
      $rootScope.log.indent.entry "ceiling:        #{$scope.memory.ceiling}"

  $scope.panes.memory.save = () ->
    if not $scope.panes.memory.validate()
      $rootScope.warning "Could not save memory settings: validation failed"
      return
    $rootScope.log.info "Saving memory settings"
    $rootScope.log.indent.entry( "earlyGen: #{$rootScope.memory.earlyGen = $scope.panes.memory.earlyGen}")
    $rootScope.log.indent.entry( "initial:  #{$rootScope.memory.initial  = $scope.panes.memory.initial}")
    $rootScope.log.indent.entry( "max:      #{$rootScope.memory.max      = $scope.panes.memory.max}")



  $scope.panes.memory.validate = ->
    # Validate memory settings
    return false  if not $scope.panes.memory.validate.initial()
    return false  if not $scope.panes.memory.validate.earlyGen()
    return false  if not $scope.panes.memory.validate.max()
    return false  if     $scope.panes.memory.earlyGen >= $scope.panes.memory.initial
    return false  if     $scope.panes.memory.max      <  $scope.panes.memory.initial + $scope.panes.memory.earlyGen
    return false  if     $scope.panes.memory.max      >  $scope.panes.memory.ceiling
    return true

  $scope.panes.memory.validate.max = ->
    # catch `undefined` from invalid values
    return false  if not $scope.panes.memory.max?
    return false  if not typeof $scope.panes.memory.max == "number"

    _max = $scope.panes.memory.max
    return false  if     _max >  $scope.panes.memory.ceiling
    return false  if     _max < ($scope.panes.memory.initial + $scope.panes.memory.earlyGen)
    return true

  $scope.panes.memory.validate.initial = ->
    return false  if not $scope.panes.memory.initial?    # catch `undefined` from invalid values
    return true

  $scope.panes.memory.validate.earlyGen = ->
    return false  if not $scope.panes.memory.earlyGen?   # catch `undefined` from invalid values
    return true


  $scope.panes.memory.validate.max.class      = ->
    return "invalid"  if not $scope.panes.memory.validate.max()
    return "critical" if     $scope.panes.memory.max < 2048
    return "warning"  if     $scope.panes.memory.max < 4096
  $scope.panes.memory.validate.initial.class  = ->
    return "invalid"  if not $scope.panes.memory.validate.initial()
    return "invalid"  if     $scope.panes.memory.initial <= $scope.panes.memory.earlyGen
    return "warning"  if     $scope.panes.memory.initial <  256
  $scope.panes.memory.validate.earlyGen.class = ->
    return "invalid"  if not $scope.panes.memory.validate.earlyGen()



  ### End per-pane functions ###



  # Iterate through and load each pane's data
  # for pane in $scope.availablePanes
  #   $scope.panes[pane].load()
  