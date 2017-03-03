'use strict'

app = angular.module 'launcher'

app.service 'settings', () ->

  ### Status ###

  # For polling
  @isReady  = () -> return false
  # Promise to allow settings-dependent code chaining
  @ready    = new Promise (resolve, reject) => @setReady = resolve  # public resolver: settings.setReady()
  @ready.then () => @isReady = () -> return true



  ### Dialog control and visibility ###

  @dialog =
    visible:    false
    pane:       null
  @dialog.isVisible =    () => return @dialog.visible
  @dialog.getPane   =    () => return @dialog.pane
  @dialog.show      =    () => @dialog.visible = true
  @dialog.hide      =    () => @dialog.visible = false
  @dialog.showPane  = (pane) =>
    @dialog.visible = true
    @dialog.pane    = pane



  ### Per-pane settings ###

  @java =
    path: null
    args: null
  @java.setPath = (newVal) => @java.path = newVal
  @java.setArgs = (newVal) => @java.args = newVal


  @memory =
    max:      null
    initial:  null
    earlyGen: null
  @memory.setMax      = (newVal) => @memory.max      = newVal
  @memory.setInitial  = (newVal) => @memory.initial  = newVal
  @memory.setEarlyGen = (newVal) => @memory.earlyGen = newVal

  return
