fs = require('fs')

fileExists = (pathName) ->
  pathName = path.resolve(pathName)
  try
    # since Node changes the fs.exists() functions with every version
    fs.closeSync( fs.openSync(pathName, "r") )
    return true
  catch e
    return false

module.exports = {
  fileExists: fileExists
}