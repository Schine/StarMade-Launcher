'use strict'

GREENWORKS_URL = 'https://s3.amazonaws.com/sm-launcher/greenworks'
JAVA_URL = 'https://s3.amazonaws.com/sm-launcher/java'

argv = require('minimist')(process.argv.slice(2))
async = require('async')
fs = require('fs')
mkdirp = require('mkdirp')
ncp = require('ncp')
gulp = require('gulp')
gutil = require('gulp-util')
path = require('path')
plugins = require('gulp-load-plugins')()
rimraf = require('rimraf')
source = require('vinyl-source-stream')
spawn = require('child_process').spawn

util = require('./src/util')

paths =
  build:
    dir: 'build'
    glob: 'build/**/*'
    lib:
      dir: 'build/lib'
    static:
      dir: 'build/static'
      glob: 'build/static/**/*'
      styles:
        dir:
          'build/static/styles'
  cache:
    electron:
      dir: 'cache/electron'
  dep:
    dir: 'dep'
    electron:
      dir: 'dep/electron'
    java:
      dir: 'dep/java'
    greenworks:
      dir: 'dep/greenworks'
      entry: 'dep/greenworks/greenworks.js'
      lib:
        dir: 'dep/greenworks/lib'
    steamworksSdk:
      dir: 'dep/steamworks'
  dist:
    dir: 'dist',
    platform:
      darwin:
        x64: 'dist/starmade-launcher-darwin-x64/starmade-launcher.app/Contents/MacOS'
      linux:
        ia32: 'dist/starmade-launcher-linux-ia32'
        x64: 'dist/starmade-launcher-linux-x64'
      win32:
        ia32: 'dist/starmade-launcher-win32-ia32'
        x64: 'dist/starmade-launcher-win32-x64'
  lib:
    dir: 'lib'
    glob: 'lib/**/*'
  nodeModules:
    dir: 'node_modules'
  package: './package.json'
  res:
    icon: 'res/starmade.ico'
    licenses:
      dir: 'res/licenses'
  src:
    dir: 'src'
    glob: 'src/**/*.coffee'
  static:
    dir: 'static'
    entries: 'static/*.js'
    fonts:
      glob: 'static/fonts/**/*'
    images:
      glob: 'static/images/**/*'
    jade:
      glob: 'static/**/*.jade'
    styles:
      main: 'static/styles/main.less'
  steamAppid: 'steam_appid.txt'

pkg = require(paths.package)
electronVersion = pkg.electronVersion
greenworksVersion = pkg.greenworksVersion
javaVersion = pkg.javaVersion

targetPlatform = argv.platform || 'current'
targetArch = argv.arch || 'current'

if targetPlatform == 'current'
  targetPlatform = process.platform

if targetArch == 'current'
  targetArch = process.arch

greenworks =
  win32: "#{paths.dep.greenworks.dir}/lib/greenworks-win32.node"
  win64: "#{paths.dep.greenworks.dir}/lib/greenworks-win64.node"
  osx64: "#{paths.dep.greenworks.dir}/lib/greenworks-osx64.node"
  linux32: "#{paths.dep.greenworks.dir}/lib/greenworks-linux32.node"
  linux64: "#{paths.dep.greenworks.dir}/lib/greenworks-linux64.node"

java =
  dir:
    win32:
      ia32: "#{paths.dep.java.dir}/win32"
      x64: "#{paths.dep.java.dir}/win64"
    darwin:
      x64: "#{paths.dep.java.dir}/osx64"
    linux:
      ia32: "#{paths.dep.java.dir}/linux32"
      x64: "#{paths.dep.java.dir}/linux64"
  url:
    win32: "#{JAVA_URL}/jre-#{javaVersion}-windows-i586.tar.gz"
    win64: "#{JAVA_URL}/jre-#{javaVersion}-windows-x64.tar.gz"
    osx64: "#{JAVA_URL}/jre-#{javaVersion}-macosx-x64.tar.gz"
    linux32: "#{JAVA_URL}/jre-#{javaVersion}-linux-i586.tar.gz"
    linux64: "#{JAVA_URL}/jre-#{javaVersion}-linux-x64.tar.gz"

redistributables =
  win32: "#{paths.dep.steamworksSdk.dir}/sdk/redistributable_bin/steam_api.dll"
  win64: "#{paths.dep.steamworksSdk.dir}/sdk/redistributable_bin/win64/steam_api64.dll"
  osx32: "#{paths.dep.steamworksSdk.dir}/sdk/redistributable_bin/osx32/libsteam_api.dylib"
  linux32: "#{paths.dep.steamworksSdk.dir}/sdk/redistributable_bin/linux32/libsteam_api.so"
  linux64: "#{paths.dep.steamworksSdk.dir}/sdk/redistributable_bin/linux64/libsteam_api.so"

licenses = path.join paths.build.static.dir, 'licenses.txt'

gulp.task 'default', ['run']

gulp.task 'bootstrap', ['greenworks', 'java']

gulp.task 'build', ['coffee', 'jade', 'less', 'copy', 'acknowledge']

gulp.task 'coffee', ->
  gulp.src paths.src.glob
    .pipe plugins.coffee()
      .on 'error', gutil.log
    .pipe plugins.sourcemaps.write()
    .pipe gulp.dest paths.build.lib.dir

gulp.task 'electron-packager', ['build', 'acknowledge'], (callback) ->
  packager = require('electron-packager')
  packager
    dir: paths.build.dir
    out: 'dist'
    name: 'starmade-launcher'
    platform: targetPlatform
    arch: targetArch
    version: electronVersion
    icon: paths.res.icon
    overwrite: true
    asar: true
    'version-string':
      FileDescription: 'StarMade Launcher'
      CompanyName: 'Schine GmbH'
      LegalCopyright: 'Copyright (C) 2015 Schine GmbH'
      ProductName: 'StarMade Launcher'
      OriginalFilename: 'starmade-launcher.exe'
  , callback

gulp.task 'greenworks', ->
  plugins.download(GREENWORKS_URL + "/greenworks-v#{greenworksVersion}-starmade-electron-#{electronVersion}.zip")
    .pipe plugins.unzip()
    .pipe gulp.dest paths.dep.greenworks.dir

javaTasks = []

downloadJavaTask = (platform) ->
  ->
    plugins.download(java.url[platform])
      .pipe plugins.gunzip()
      .pipe plugins.untar()
      .pipe gulp.dest path.join(paths.dep.java.dir, platform)

for platform, url of java.url
  taskName = "java-#{platform}"
  gulp.task taskName, downloadJavaTask(platform)
  javaTasks.push taskName

gulp.task 'java', javaTasks

gulp.task 'jade', ->
  gulp.src paths.static.jade.glob
    .pipe plugins.jade
      pretty: true
    .pipe gulp.dest paths.build.static.dir

gulp.task 'less', ->
  gulp.src paths.static.styles.main
    .pipe plugins.less()
    .pipe gulp.dest paths.build.static.styles.dir

copyTasks = [
  'copy-package'
  'copy-static-entries'
  'copy-static-fonts'
  'copy-static-images'
]

gulp.task 'copy-package', ->
  gulp.src paths.package
    .pipe gulp.dest paths.build.dir

gulp.task 'copy-static-entries', ->
  gulp.src paths.static.entries
    .pipe gulp.dest paths.build.static.dir

gulp.task 'copy-static-fonts', ->
  gulp.src paths.static.fonts.glob
    .pipe gulp.dest path.join(paths.build.static.dir, 'fonts')

gulp.task 'copy-static-images', ->
  gulp.src paths.static.images.glob
    .pipe gulp.dest path.join(paths.build.static.dir, 'images')

copyModuleTask = (name) ->
  ->
    src = path.join paths.nodeModules.dir, name, '**/*'
    dest = path.join paths.build.dir, 'node_modules', name
    gulp.src src
      .pipe gulp.dest dest

acknowledgeTasks = [
  'acknowledge-clear'
  'acknowledge-electron'
  'acknowledge-bebas-neue'
  'acknowledge-ubuntu'
  'acknowledge-java'
  'acknowledge-java-thirdparty'
  'acknowledge-java-thirdparty-javafx'
  'acknowledge-greenworks'
]

gulp.task 'acknowledge-clear', (callback) ->
  fs.unlink licenses, (err) ->
    if err
      mkdirp paths.build.static.dir, callback
    else
      callback()

gulp.task 'acknowledge-starmade', ['acknowledge-clear'], (callback) ->
  fs.readFile path.join(paths.res.licenses.dir, 'starmade'), (err, contents) ->
    data = contents + '\n' +
      'This application contains third-party libraries and fonts in accordance with the following\nlicenses:\n' +
      '--------------------------------------------------------------------------------\n\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-electron', ['acknowledge-clear', 'acknowledge-starmade'], (callback) ->
  fs.readFile path.join(paths.res.licenses.dir, 'electron'), (err, data) ->
    return callback(err) if err
    data = 'electron\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-bebas-neue', ['acknowledge-clear', 'acknowledge-starmade'], (callback) ->
  fs.readFile path.join(paths.res.licenses.dir, 'bebas_neue'), (err, data) ->
    return callback(err) if err
    data = 'bebas neue font\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-ubuntu', ['acknowledge-clear', 'acknowledge-starmade'], (callback) ->
  fs.readFile path.join(paths.res.licenses.dir, 'ubuntu'), (err, data) ->
    return callback(err) if err
    data = 'ubuntu fonts\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-java', ['acknowledge-clear', 'acknowledge-starmade'], (callback) ->
  fs.readFile path.join(java.dir[process.platform][process.arch], util.getJreDirectory(javaVersion), 'LICENSE'), (err, data) ->
    return callback(err) if err
    data = 'java\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-java-thirdparty', ['acknowledge-clear', 'acknowledge-starmade', 'acknowledge-java'], (callback) ->
  fs.readFile path.join(java.dir[process.platform][process.arch], util.getJreDirectory(javaVersion), 'THIRDPARTYLICENSEREADME.txt'), (err, data) ->
    return callback(err) if err
    data = 'java third party\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-java-thirdparty-javafx', ['acknowledge-clear', 'acknowledge-starmade', 'acknowledge-java', 'acknowledge-java-thirdparty'], (callback) ->
  fs.readFile path.join(java.dir[process.platform][process.arch], util.getJreDirectory(javaVersion), 'THIRDPARTYLICENSEREADME-JAVAFX.txt'), (err, data) ->
    return callback(err) if err
    data = 'java third party javafx\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-greenworks', ['acknowledge-clear', 'acknowledge-starmade'], (callback) ->
  fs.readFile path.join(paths.res.licenses.dir, 'greenworks'), (err, data) ->
    return callback(err) if err
    data = 'greenworks\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

acknowledgeModuleTask = (name) ->
  (callback) ->
    moduleLicense = path.join paths.nodeModules.dir, name, 'LICENSE'
    moduleLicenseLower = path.join paths.nodeModules.dir, name, 'license'
    moduleLicence = path.join paths.nodeModules.dir, name, 'LICENCE'
    modulePkg = require(path.resolve(path.join(paths.nodeModules.dir, name, 'package.json')))

    data = "#{modulePkg.name}\n" +
      '--------------------------------------------------------------------------------\n'

    if fs.existsSync moduleLicense
      fs.readFile moduleLicense, (err, contents) ->
        return callback(err) if err
        data += contents.toString() + '\n'
        fs.appendFile licenses, data, callback
    else if fs.existsSync moduleLicenseLower
      fs.readFile moduleLicenseLower, (err, contents) ->
        return callback(err) if err
        data += contents.toString() + '\n'
        fs.appendFile licenses, data, callback
    else if fs.existsSync moduleLicence
      fs.readFile moduleLicence, (err, contents) ->
        return callback(err) if err
        data += contents.toString() + '\n'
        fs.appendFile licenses, data, callback
    else
      fs.readFile path.join(paths.res.licenses.dir, name), (err, contents) ->
        return callback(err) if err
        data += contents.toString() + '\n'
        fs.appendFile licenses, data, callback

# Create copy tasks for each non-development dependencies
# Also create tasks to add their license contents to the licenses file
for name of pkg.dependencies
  copyTaskName = "copy-module-#{name}"
  acknowledgeTaskName = "acknowledge-module-#{name}"
  gulp.task copyTaskName, copyModuleTask(name)
  gulp.task acknowledgeTaskName, ['acknowledge-clear', 'acknowledge-starmade'], acknowledgeModuleTask(name)
  copyTasks.push copyTaskName
  acknowledgeTasks.push acknowledgeTaskName

gulp.task 'copy', copyTasks
gulp.task 'acknowledge', acknowledgeTasks

gulp.task 'package', ['build', 'electron-packager', 'package-greenworks', 'package-java', 'package-redistributables', 'package-steam-appid']

packageGreenworksTasks = [
  'electron-packager'
]

packageGreenworksNativeTask = (platform) ->
  ->
    os = platform.slice(0, -2)
    arch = platform.slice(-2)

    switch os
      when 'osx'
        os = 'darwin'
      when 'win'
        os = 'win32'

    switch arch
      when '32'
        arch = 'ia32'
      when '64'
        arch = 'x64'

    if targetPlatform != 'all'
      return unless os == targetPlatform

    if targetArch != 'all'
      return unless arch == targetArch

    gulp.src greenworks[platform]
      .pipe gulp.dest path.join(paths.dist.platform[os][arch], 'dep', 'greenworks', 'lib')

for platform of greenworks
  taskName = "package-greenworks-#{platform}"
  gulp.task taskName, ['electron-packager'], packageGreenworksNativeTask(platform)
  packageGreenworksTasks.push taskName

gulp.task 'package-greenworks', packageGreenworksTasks, ->
  gulp.src paths.dep.greenworks.entry
    .pipe gulp.dest path.join(paths.dist.platform.win32.ia32, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.win32.x64, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.linux.ia32, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.linux.x64, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.darwin.x64, 'dep', 'greenworks')

packageJavaTasks = [
  'electron-packager'
]

packageJavaTask = (platform, arch) ->
  ->
    filter = plugins.filter('**/*/bin/*')
    javaDir = path.join(java.dir[platform][arch], util.getJreDirectory(javaVersion))

    if targetPlatform != 'all'
      return unless platform == targetPlatform

    if targetArch != 'all'
      return unless arch == targetArch

    gulp.src "#{javaDir}/**/*", {base: java.dir[platform][arch]}
      .pipe filter
      .pipe plugins.chmod 755
      .pipe filter.restore()
      .pipe gulp.dest path.join(paths.dist.platform[platform][arch], 'dep', 'java')

for platform of java.dir
  for arch of java.dir[platform]
    taskName = "package-java-#{platform}-#{arch}"
    gulp.task taskName, ['electron-packager'], packageJavaTask(platform, arch)
    packageJavaTasks.push taskName

gulp.task 'package-java', packageJavaTasks

packageRedistributablesTasks = [
  'electron-packager'
]

packageRedistributablesTask = (platform) ->
  ->
    os = platform.slice(0, -2)
    arch = platform.slice(-2)

    switch os
      when 'osx'
        os = 'darwin'
      when 'win'
        os = 'win32'

    switch arch
      when '32'
        if os == 'darwin'
          # Place the 32-bit OS X binary in the 64-bit distribution
          arch = 'x64'
        else
          arch = 'ia32'
      when '64'
        arch = 'x64'

    if targetPlatform != 'all'
      return unless os == targetPlatform

    if targetArch != 'all'
      return unless arch == targetArch

    gulp.src redistributables[platform]
      .pipe gulp.dest path.join(paths.dist.platform[os][arch], 'dep', 'greenworks', 'lib')

for platform of redistributables
  taskName = "package-redistributables-#{platform}"
  gulp.task taskName, ['electron-packager'], packageRedistributablesTask(platform)
  packageRedistributablesTasks.push taskName

gulp.task 'package-redistributables', packageRedistributablesTasks

gulp.task 'package-steam-appid', ['electron-packager'], ->
  gulp.src paths.steamAppid
    .pipe gulp.dest paths.dist.platform.win32.ia32
    .pipe gulp.dest paths.dist.platform.win32.x64
    .pipe gulp.dest paths.dist.platform.linux.ia32
    .pipe gulp.dest paths.dist.platform.linux.x64
    .pipe gulp.dest paths.dist.platform.darwin.x64

gulp.task 'run', ['package'], ->
  appDir = paths.dist.platform[process.platform][process.arch]
  if process.platform == 'darwin'
    app = path.join appDir, 'Electron'
  else
    app = path.join appDir, 'starmade-launcher'
    app += '.exe' if process.platform == 'win32'
  app = path.resolve app

  spawn app, [],
    cwd: appDir
    stdio: 'inherit'

  return
