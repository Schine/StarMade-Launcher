'use strict'

app = angular.module 'launcher'

app.service 'settings', () ->
  @dialog =
    visible:    false
    tab:        null
  @dialog.isVisible =    () => return @dialog.visible
  @dialog.getTab    =    () => return @dialog.tab
  @dialog.show      =    () => @dialog.visible = true
  @dialog.hide      =    () => @dialog.visible = false
  @dialog.showTab   = (tab) =>
    @dialog.visible = true
    @dialog.tab     = tab

  return
