#log = require('./log.js'); log.entry("entry"); log.info("info"); log.warning("warning"); log.indent(); log.error("error"); log.indent(); log.fatal("fatal"); log.outdent(); log.debug("debug"); log.outdent(); log.end("end"); log.important("important"); log.raw("raw"); log.raw("raw2\n");

'use strict'

fs   = require 'fs'
path = require 'path'


log_descriptor   = null
log_level        = 1
log_indent_level = 0

levels =
  normal:  0
  error:   0
  info:    1
  warning: 2
  debug:   5
  verbose: 10

prefixes =
  normal:    "         "
  important: "   !!!   "
  info:      "  info   "
  warning:   " warning "
  error:     "  error  "
  fatal:     "  FATAL  "
  debug:     " (debug) "
  verbose:   "(verbose)"
  meta:      " (meta)  "
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
  raw  "#{new Date}\n"
  meta "Opened log file for #{if method=="w" then "writing" else "appending"}."



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
    data += "\n"                        if type != "raw"

    bytes = fs.writeSync(log_descriptor, data)

  catch e
    open_logfile()
    try
      this.warning("Could not write to log.  Attempting re-write.", 0)
      bytes = fs.writeSync(log_descriptor, data)
    catch e
      open_logfile()
      this.error("Re-write failed.  Log entry lost.", 0)



# Helper functions
entry     = (str, level=levels.normal)  -> log(str, level, "normal")
info      = (str, level=levels.info)    -> log(str, level, "info")
warning   = (str, level=levels.warning) -> log(str, level, "warning")
error     = (str, level=levels.normal)  -> log(str, level, "error")
fatal     = (str, level=levels.normal)  -> log(str, level, "fatal")
debug     = (str, level=levels.debug)   -> log(str, level, "debug")
verbose   = (str, level=levels.verbose) -> log(str, level, "verbose")
important = (str, level=levels.normal)  -> log(str, level, "important")
end       = (str, level=levels.normal)  -> log(str, level, "end")
raw       = (str, level=levels.normal)  -> log(str, level, "raw")
meta      = (str, level=levels.verbose) -> log(str, level, "meta")



set_level = (level) ->
  log_level = level


indent_level    = (   ) -> log_indent_level
increase_indent = (n=1) -> log_indent_level += n
decrease_indent = (n=1) -> log_indent_level  = Math.max(0, log_indent_level-n)



module.exports = {
  # Constants
  levels:        levels           # log-level constants
  prefixes:      prefixes         # log-level prefixes

  # Functions
  entry:         entry            # normal log entry
  info:          info             # info   log entry
  warning:       warning          # etc.
  error:         error            # Standard error
  fatal:         fatal            # Fatal error
  debug:         debug
  verbose:       verbose
  important:     important
  end:           end              # The beginning of the end
  raw:           raw              # No timestamp, newlines, etc.

  indent_level:  indent_level
  indent:        increase_indent
  outdent:       decrease_indent

  set_level:     set_level
}
