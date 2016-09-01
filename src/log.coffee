'use strict'

fs   = require 'fs'
path = require 'path'


log_descriptor   = null
log_level        = 0
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
log_indent = (n=1, level=0) ->
  return if level > log_level
  log_indent_level += n


# Decreases log indent (with optional log-level)
log_outdent = (n=1, level=0) ->
  return if level > log_level
  log_indent_level  = Math.max(0, log_indent_level-n)


# Helper functions (single-indent)
log_indent.entry     = (str, level) -> log_indent();  log_entry     str, level;  log_outdent();
log_indent.info      = (str, level) -> log_indent();  log_info      str, level;  log_outdent();
log_indent.event     = (str, level) -> log_indent();  log_event     str, level;  log_outdent();
log_indent.game      = (str, level) -> log_indent();  log_game      str, level;  log_outdent();
log_indent.warning   = (str, level) -> log_indent();  log_warning   str, level;  log_outdent();
log_indent.error     = (str, level) -> log_indent();  log_error     str, level;  log_outdent();
log_indent.fatal     = (str, level) -> log_indent();  log_fatal     str, level;  log_outdent();
log_indent.debug     = (str, level) -> log_indent();  log_debug     str, level;  log_outdent();
log_indent.verbose   = (str, level) -> log_indent();  log_verbose   str, level;  log_outdent();
log_indent.important = (str, level) -> log_indent();  log_important str, level;  log_outdent();
log_indent.update    = (str, level) -> log_indent();  log_update    str, level;  log_outdent();
log_indent.end       = (str, level) -> log_indent();  log_end       str, level;  log_outdent();
log_indent.raw       = (str, level) -> log_indent();  log_raw       str, level;  log_outdent();
log_indent.meta      = (str, level) -> log_indent();  log_meta      str, level;  log_outdent();




module.exports = {
  # Constants
  levels:        levels           # Log-level constants
  prefixes:      prefixes         # Log-level prefixes

  # Functions
  entry:         log_entry        # Normal entry
  info:          log_info         # Info   entry
  event:         log_event        # Event  entry
  game:          log_game         # Used for captured game output (log-level 3)
  warning:       log_warning      # Not an error
  error:         log_error        # Normal error
  fatal:         log_fatal        # Fatal  error
  debug:         log_debug        # Log-level 5
  verbose:       log_verbose      # Log-level 10
  important:     log_important
  update:        log_update       # Used by the self-updater
  end:           log_end          # The beginning of the end
  raw:           log_raw          # No timestamp, newlines, etc.

  indent_level:  indent_level     # Returns current indent level
  indent:        log_indent       # indent(num=1, level=normal) plus indent.<entry_type>() single-indent helper functions
  outdent:       log_outdent      # outdent(num=1, level=normal)

  set_level:     set_level        # Sets log-level
}
