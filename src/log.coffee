'use strict'

fs   = require 'fs'
path = require 'path'


log_descriptor   = null
log_level        = 1
log_indent_level = 0

levels =
  normal:  0
  error:   0
  fatal:   0
  info:    0
  event:   0
  warning: 0
  game:    3
  debug:   5
  verbose: 10

prefixes =
  normal:    "         "
  important: "  !!!!   "
  game:      " [game]  "
  info:      "  info   "
  event:     "  event  "
  warning:   " warning "
  error:     "  error  "
  fatal:     "**FATAL**"
  debug:     " (debug) "
  verbose:   "(verbose)"
  meta:      " (meta)  "
  update:    " updater "
  end:       " --end-- "
  raw:       ""


# For alignment
timestamp_padding = new Array(
                      # Length of the timestring + some for excess padding
                      ((new Date().toLocaleTimeString()).length + 2)+1
                    ).join(" ")


# Returns a right-padded timestamp in the (locale-dependent) format: "3:36:45 PM  "
timestamp = () ->
  stamp  = new Date().toLocaleTimeString()            # Get the timestamp string
  stamp += timestamp_padding.substring(stamp.length)  # Append remaining padding


# returns (" | " * log_indent_level)
indenting = () ->
  str  = ""
  if log_indent_level > 0
    str += " | " for x in [1..log_indent_level]
  str


prefix = (type) ->
  return "" if type == "raw"
  "  #{prefixes[type]}    #{indenting()}"  # two leading spaces because of timestamp padding



open_logfile = () ->
  method = ""
  if log_descriptor != null
    # Already open?  Close and re-open for appending
    fs.closeSync(log_descriptor)
    method = "a"
  else
    # Otherwise: create/overwrite
    method = "w"

  log_descriptor = fs.openSync( path.join(".", "launcher.log"), method )
  log_raw  "#{new Date}\n"
  log_meta "Opened log file for #{if method=="w" then "writing" else "appending"}."



# This is where the magic happens.
log = (str,  level=0,  type="normal") ->
  # Enforce log-level
  return  if level > log_level

  if (log_descriptor == null)
    open_logfile()

  try
    console.log  prefix(type) + str

    data  = ""
    data += timestamp() + prefix(type)  if type != "raw"
    data += str
    data += "\n"                        if type != "raw"  &&  not data.endsWith("\n")

    bytes = fs.writeSync(log_descriptor, data)

  catch e
    # Should catch other filesystem errors here
    open_logfile()
    try
      # This assumes `data` is the cause.
      this.warning("Could not write to log.  Attempting re-write.", 0)
      bytes = fs.writeSync(log_descriptor, data)
    catch e
      open_logfile()
      this.error("Re-write failed.  Log entry lost.", 0)



# Helper functions
log_entry     = (str, level=levels.normal)  -> log(str, level, "normal")
log_info      = (str, level=levels.info)    -> log(str, level, "info")
log_event     = (str, level=levels.event)   -> log(str, level, "event")
log_game      = (str, level=levels.game)    -> log(str, level, "game")
log_warning   = (str, level=levels.warning) -> log(str, level, "warning")
log_error     = (str, level=levels.normal)  -> log(str, level, "error")
log_fatal     = (str, level=levels.normal)  -> log(str, level, "fatal")
log_debug     = (str, level=levels.debug)   -> log(str, level, "debug")
log_verbose   = (str, level=levels.verbose) -> log(str, level, "verbose")
log_important = (str, level=levels.normal)  -> log(str, level, "important")
log_update    = (str, level=levels.normal)  -> log(str, level, "update")
log_end       = (str, level=levels.normal)  -> log(str, level, "end")
log_raw       = (str, level=levels.normal)  -> log(str, level, "raw")
log_meta      = (str, level=levels.verbose) -> log(str, level, "meta")


# Only log entries with this log-level or below.
set_level = (level) ->
  log_level = level
  level_name = null
  for key,val of levels
    level_name or= "#{key} (#{val})" if val==level
  level_name or= level
  log_raw "Logging level: #{level_name}\n\n"


# Returns current log indent level
indent_level    = () ->
  log_indent_level

# Increases log indent (with optional log-level)
increase_indent = (n=1, level=0) ->
  return if level > log_level
  log_indent_level += n

# Decreases log indent (with optional log-level)
decrease_indent = (n=1, level=0) ->
  return if level > log_level
  log_indent_level  = Math.max(0, log_indent_level-n)



module.exports = {
  # Constants
  levels:        levels       # log-level constants
  prefixes:      prefixes     # log-level prefixes

  # Functions
  entry:         log_entry        # normal entry
  info:          log_info         # info   entry
  event:         log_event        # etc.
  game:          log_game         # used for captured game output
  warning:       log_warning
  error:         log_error        # Standard error
  fatal:         log_fatal        # Fatal error
  debug:         log_debug
  verbose:       log_verbose
  important:     log_important
  update:        log_update
  end:           log_end          # The beginning of the end
  raw:           log_raw          # No timestamp, newlines, etc.

  indent_level:  indent_level
  indent:        increase_indent  # indent `n` levels, optionally log-level dependent
  outdent:       decrease_indent  # outdent ...

  set_level:     set_level
}
