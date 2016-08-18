fs   = require('fs')
path = require('path')

fileExists = (fullpath) ->
  # since Node changes the fs.exists() functions with every version
  try
    fullpath = path.resolve(fullpath)
    return true  if path.basename(fullpath) in fs.readdirSync(path.dirname(fullpath))
    return false
  catch e
    return false

module.exports = {
  fileExists: fileExists
}