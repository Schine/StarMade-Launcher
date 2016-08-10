ipc = require('ipc')


# Logging
log_entry     = (msg, level) -> ipc.send('log-entry',     msg, level) # Sync would be better
log_info      = (msg, level) -> ipc.send('log-info',      msg, level) # for logging; however,
log_event     = (msg, level) -> ipc.send('log-event',     msg, level) # that causes $apply()
log_game      = (msg, level) -> ipc.send('log-game',      msg, level) # in AngularJS to die.
log_warning   = (msg, level) -> ipc.send('log-warning',   msg, level)
log_error     = (msg, level) -> ipc.send('log-error',     msg, level)
log_fatal     = (msg, level) -> ipc.send('log-fatal',     msg, level)
log_debug     = (msg, level) -> ipc.send('log-debug',     msg, level)
log_verbose   = (msg, level) -> ipc.send('log-verbose',   msg, level)
log_important = (msg, level) -> ipc.send('log-important', msg, level)
log_end       = (msg, level) -> ipc.send('log-end',       msg, level)
log_raw       = (msg, level) -> ipc.send('log-raw',       msg, level)

log_levels    = ipc.sendSync('log-levels')

log_indent    = (num, level) -> ipc.sendSync('log-indent',  num, level)
log_outdent   = (num, level) -> ipc.sendSync('log-outdent', num, level)


module.exports = {
  entry:      log_entry
  info:       log_info
  event:      log_event
  game:       log_game
  warning:    log_warning
  error:      log_error
  fatal:      log_fatal
  debug:      log_debug
  verbose:    log_verbose
  important:  log_important
  end:        log_end
  raw:        log_raw

  levels:     log_levels

  indent:     log_indent
  outdent:    log_outdent
}