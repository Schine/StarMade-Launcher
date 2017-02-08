os         = require('os')
path       = require('path')
sanitizefn = require('sanitize-filename')



# Cross-platform path sanitizing
# Relies on the `sanitize-filename` npm package
##! Possible issues:
#     * (Win32)  A malformed drive letter causes the malformed path to be treated as relative to the current directory.  This is due to the initial `path.resolve()`
sanitize = (str) ->
  # Resolve into an absolute path first
  str = path.resolve(str)
  # and split the resulting path into tokens
  tokens = str.split(path.sep)

  # For Win32, retain the root drive
  root = null
  if os.platform() == "win32"
    root = tokens.shift()
    # Sanitize it, and add the ":" back
    root = sanitizefn(root) + ":"

  # Sanitize each token in turn
  for token, index in tokens
    tokens[index] = sanitizefn(token)

  # Remove all empty elements
  tokens.filter (n) ->
    n != ""

  # Rebuild array
  new_path = tokens.join( path.sep )

  # Restore the root of the path
  if os.platform() == "win32"
    new_path = path.join(root, new_path)  # Win32: drive letter
  else
    new_path = path.sep + new_path        # POSIX: leading /

  # And return our new, sparkling-clean path
  new_path



module.exports = {
  sanitize: sanitize
}