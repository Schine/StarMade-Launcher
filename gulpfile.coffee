'use strict'

JAVA_URL = 'https://s3.amazonaws.com/sm-launcher/java'
STEAMWORKS_SDK_URL = 'https://partner.steamgames.com/downloads/steamworks_sdk_133b.zip'

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
      deps:
        dir: 'dep/greenworks/deps'
        steamworksSdk:
          dir: 'dep/greenworks/deps/steamworks_sdk'
  dist:
    dir: 'dist',
    platform:
      # TODO: Figure out paths for OS X
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

redistributables =
  win32: "#{paths.dep.greenworks.deps.steamworksSdk.dir}/steam_api.dll"
  win64: "#{paths.dep.greenworks.deps.steamworksSdk.dir}/win64/steam_api64.dll"
  osx32: "#{paths.dep.greenworks.deps.steamworksSdk.dir}/osx32/libsteam_api.dylib"
  linux32: "#{paths.dep.greenworks.deps.steamworksSdk.dir}/linux32/libsteam_api.so"
  linux64: "#{paths.dep.greenworks.deps.steamworksSdk.dir}/linux64/libsteam_api.so"

pkg = require(paths.package)
electronVersion = pkg.electronVersion
javaVersion = pkg.javaVersion

java =
  win32: "#{JAVA_URL}/jre-#{javaVersion}-windows-i586.tar.gz"
  win64: "#{JAVA_URL}/jre-#{javaVersion}-windows-x64.tar.gz"
  osx64: "#{JAVA_URL}/jre-#{javaVersion}-macosx-x64.tar.gz"
  linux32: "#{JAVA_URL}/jre-#{javaVersion}-linux-i586.tar.gz"
  linux64: "#{JAVA_URL}/jre-#{javaVersion}-linux-x64.tar.gz"

licenses = path.join paths.build.static.dir, 'licenses.txt'

gulp.task 'default', ['run']

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
    platform: 'all'
    arch: 'all'
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

gulp.task 'greenworks', ['greenworks-clean', 'greenworks-npm', 'greenworks-build']

gulp.task 'greenworks-clean', (callback) ->
  rimraf path.join(paths.dep.greenworks.dir, 'build'), callback
  return

gulp.task 'greenworks-npm', ['greenworks-clean', 'greenworks-steamworks-sdk'], (callback) ->
  npm = 'npm'
  npm += '.cmd' if process.platform == 'win32'

  ps = spawn npm, ['install', '--ignore-scripts'],
    cwd: paths.dep.greenworks.dir
    stdio: 'inherit'

  ps.on 'close', ->
    callback()

  return

# greenworks-npm will build, but not for Electron
gulp.task 'greenworks-build', ['greenworks-steamworks-sdk', 'greenworks-clean', 'greenworks-npm'], (callback) ->
  # No Steamworks support for OS X 64-bit
  return callback() if process.platform == 'darwin'

  nodeGyp = 'node-gyp'
  nodeGyp += '.cmd' if process.platform == 'win32'

  arch = process.arch

  ps = spawn nodeGyp, [
    'rebuild'
    "--target=#{electronVersion}"
    "--arch=#{arch}"
    '--dist-url=https://gh-contractor-zcbenz.s3.amazonaws.com/atom-shell/dist'
  ],
    cwd: paths.dep.greenworks.dir
    stdio: 'inherit'

  ps.on 'close', ->
    callback()

  return

gulp.task 'greenworks-steamworks-sdk-download', ->
  return if fs.existsSync paths.dep.greenworks.deps.steamworksSdk.dir

  plugins.download(STEAMWORKS_SDK_URL)
    .pipe plugins.unzip()
    .pipe gulp.dest paths.dep.greenworks.deps.dir

# Hacky way to rename the extracted folder from the Steamworks SDK zip file
gulp.task 'greenworks-steamworks-sdk', ['greenworks-steamworks-sdk-download'], (callback) ->
  return callback() if fs.existsSync paths.dep.greenworks.deps.steamworksSdk.dir

  fs.rename path.join(paths.dep.greenworks.deps.dir, 'sdk'), paths.dep.greenworks.deps.steamworksSdk.dir, (err) ->
    callback(err)

gulp.task 'java', ->
  return if fs.existsSync paths.dep.java.dir

  switch process.platform
    when 'win32'
      if process.arch == 'ia32'
        platform = 'win32'
      else
        platform = 'win64'
    when 'darwin'
      platform = 'osx64'
    when 'linux'
      if process.arch == 'ia32'
        platform = 'linux32'
      else
        platform = 'linux64'
    else
      throw 'Unsupported platform'

  plugins.download(java[platform])
    .pipe plugins.gunzip()
    .pipe plugins.untar()
    .pipe gulp.dest paths.dep.java.dir

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

gulp.task 'acknowledge-java', ['acknowledge-clear', 'acknowledge-starmade', 'java'], (callback) ->
  fs.readFile path.join(paths.dep.java.dir, util.getJreDirectory(javaVersion), 'LICENSE'), (err, data) ->
    return callback(err) if err
    data = 'java\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-java-thirdparty', ['acknowledge-clear', 'acknowledge-starmade', 'acknowledge-java'], (callback) ->
  fs.readFile path.join(paths.dep.java.dir, util.getJreDirectory(javaVersion), 'THIRDPARTYLICENSEREADME.txt'), (err, data) ->
    return callback(err) if err
    data = 'java third party\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-java-thirdparty-javafx', ['acknowledge-clear', 'acknowledge-starmade', 'acknowledge-java', 'acknowledge-java-thirdparty'], (callback) ->
  fs.readFile path.join(paths.dep.java.dir, util.getJreDirectory(javaVersion), 'THIRDPARTYLICENSEREADME-JAVAFX.txt'), (err, data) ->
    return callback(err) if err
    data = 'java third party javafx\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

gulp.task 'acknowledge-greenworks', ['acknowledge-clear', 'acknowledge-starmade', 'greenworks'], (callback) ->
  fs.readFile path.join(paths.dep.greenworks.dir, 'LICENSE'), (err, data) ->
    return callback(err) if err
    data = 'greenworks\n' +
      '--------------------------------------------------------------------------------\n' +
      data.toString() + '\n'
    fs.appendFile licenses, data, callback

acknowledgeModuleTask = (name) ->
  (callback) ->
    moduleLicense = path.join paths.nodeModules.dir, name, 'LICENSE'
    moduleLicence = path.join paths.nodeModules.dir, name, 'LICENCE'
    modulePkg = require(path.resolve(path.join(paths.nodeModules.dir, name, 'package.json')))

    data = "#{modulePkg.name}\n" +
      '--------------------------------------------------------------------------------\n'

    if fs.existsSync moduleLicense
      fs.readFile moduleLicense, (err, contents) ->
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

gulp.task 'package', ['build', 'electron-packager', 'package-greenworks', 'package-java', 'package-steam-appid']

gulp.task 'package-greenworks', ['greenworks', 'electron-packager'], ->
  if process.platform == 'darwin'
    # No 64-bit Steamworks binary
    return

  gulp.src [
      'dep/greenworks/greenworks.js'
      'dep/greenworks/lib/**/*'
    ]
    , {base: 'dep/greenworks'}
    .pipe gulp.dest path.join(paths.dist.platform.win32.ia32, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.win32.x64, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.linux.ia32, 'dep', 'greenworks')
    .pipe gulp.dest path.join(paths.dist.platform.linux.x64, 'dep', 'greenworks')
    # TODO: Figure out paths for OS X

gulp.task 'package-java', ['java', 'electron-packager'], ->
  filter = plugins.filter('**/*/bin/*')

  gulp.src "#{paths.dep.java.dir}/**/*", {base: paths.dep.java.dir}
    .pipe filter
    .pipe plugins.chmod 755
    .pipe filter.restore()
    .pipe gulp.dest path.join(paths.dist.platform.win32.ia32, 'dep', 'java')
    .pipe gulp.dest path.join(paths.dist.platform.win32.x64, 'dep', 'java')
    .pipe gulp.dest path.join(paths.dist.platform.linux.ia32, 'dep', 'java')
    .pipe gulp.dest path.join(paths.dist.platform.linux.x64, 'dep', 'java')
    # TODO: Figure out paths for OS X

gulp.task 'package-steam-appid', ['electron-packager'], ->
  return if process.platform == 'darwin'

  gulp.src paths.steamAppid
    .pipe gulp.dest paths.dist.platform.win32.ia32
    .pipe gulp.dest paths.dist.platform.win32.x64
    .pipe gulp.dest paths.dist.platform.linux.ia32
    .pipe gulp.dest paths.dist.platform.linux.x64
    # TODO: Figure out paths for OS X

gulp.task 'run', ['build'], ->
  electron = './node_modules/.bin/electron'
  electron += '.cmd' if process.platform == 'win32'
  electron = path.resolve electron

  spawn electron, [paths.build.dir],
    stdio: 'inherit'

  return
