'use strict'

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
spawn = require('child_process').spawn
standaloneGruntRunner = require('standalone-grunt-runner')

paths =
  build:
    dir: 'build'
    glob: 'build/**/*'
    styles:
      dir:
        'build/styles'
  cache:
    electron:
      dir: 'cache/electron'
  dep:
    dir: 'dep'
    electron:
      dir: 'dep/electron'
    greenworks:
      dir: 'dep/greenworks'
      deps:
        dir: 'dep/greenworks/deps'
        steamworksSdk:
          dir: 'dep/greenworks/deps/steamworks_sdk'
  dist:
    dir: 'dist',
    app:
      executable:
        mac: 'dist/Electron.app/Contents/MacOS/electron'
        others: 'dist/electron'
      resources:
        mac: 'dist/Electron.app/Contents/Resources/app'
        others: 'dist/resources/app'
  lib:
    dir: 'lib'
    glob: 'lib/**/*'
  package: './package.json'
  src:
    dir: 'src'
    glob: 'src/**/*.coffee'
  static:
    dir: 'static'
    entries: 'static/*.js'
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

gulp.task 'default', ['run']

gulp.task 'asar', ['package-launcher', 'package-greenworks', 'package-modules'], ->
  if process.platform == 'darwin'
    resourcesDir = paths.dist.app.resources.mac
  else
    resourcesDir = paths.dist.app.resources.others

  gulp.src "#{resourcesDir}/**/*"
    .pipe plugins.asar 'app.asar'
    .pipe gulp.dest path.join(resourcesDir, '..')

gulp.task 'remove-resources-dir', ['asar'], (callback) ->
  if process.platform == 'darwin'
    resourcesDir = paths.dist.app.resources.mac
  else
    resourcesDir = paths.dist.app.resources.others

  rimraf resourcesDir, callback
  return

gulp.task 'coffee', ->
  gulp.src paths.src.glob
    .pipe plugins.coffee()
      .on 'error', gutil.log
    .pipe plugins.sourcemaps.write()
    .pipe gulp.dest paths.lib.dir

gulp.task 'download-electron', (callback) ->
  async.map [
    paths.cache.electron.dir
    paths.dep.electron.dir
  ], mkdirp, (err) ->
    return callback(err) if err

    standaloneGruntRunner 'download-electron',
      config:
        version: electronVersion
        downloadDir: paths.cache.electron.dir
        outputDir: paths.dep.electron.dir
      npm: 'grunt-download-electron'
      ->
        callback()

  return

gulp.task 'greenworks', ['greenworks-npm', 'greenworks-build']

gulp.task 'greenworks-npm', ['greenworks-steamworks-sdk'], (callback) ->
  npm = 'npm'
  npm += '.cmd' if process.platform == 'win32'

  ps = spawn npm, ['install'],
    cwd: paths.dep.greenworks.dir
    stdio: 'inherit'

  ps.on 'close', ->
    callback()

  return

# greenworks-npm will build, but not for Electron
gulp.task 'greenworks-build', ['greenworks-steamworks-sdk', 'greenworks-npm'], (callback) ->
  nodeGyp = 'node-gyp'
  nodeGyp += '.cmd' if process.platform == 'win32'

  arch = process.auth

  # grunt-download-electron will download the 32-bit version of Electron
  # if on Windows
  arch = 'ia32' if process.platform == 'win32'

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

gulp.task 'jade', ->
  gulp.src paths.static.jade.glob
    .pipe plugins.jade
      pretty: true
    .pipe gulp.dest paths.build.dir

gulp.task 'less', ->
  gulp.src paths.static.styles.main
    .pipe plugins.less()
    .pipe gulp.dest paths.build.styles.dir

gulp.task 'package', ['package-launcher', 'package-greenworks', 'package-modules', 'remove-resources-dir']

gulp.task 'package-launcher', ['coffee', 'jade', 'less', 'download-electron'], (callback) ->
  ncp paths.dep.electron.dir, paths.dist.dir, (err) ->
    return callback(err) if err

    if process.platform == 'darwin'
      resourcesDir = paths.dist.app.resources.mac
    else
      resourcesDir = paths.dist.app.resources.others

    mkdirp resourcesDir, (err) ->
      return callback(err) if err

      gulp.src paths.package
        .pipe gulp.dest resourcesDir

      gulp.src paths.lib.glob
        .pipe gulp.dest path.join(resourcesDir, 'lib')

      gulp.src paths.static.entries
        .pipe gulp.dest path.join(resourcesDir, 'static')

      gulp.src paths.build.glob
        .pipe gulp.dest path.join(resourcesDir, 'static')

      gulp.src paths.static.images.glob
        .pipe gulp.dest path.join(resourcesDir, 'static', 'images')

      gulp.src redistributables.win32
        .pipe gulp.dest paths.dist.dir

      gulp.src paths.steamAppid
        .pipe gulp.dest paths.dist.dir

      callback()

  return

gulp.task 'package-greenworks', ['package-launcher'], ->
  if process.platform == 'darwin'
    resourcesDir = paths.dist.app.resources.mac
  else
    resourcesDir = paths.dist.app.resources.others

  gulp.src 'dep/greenworks/**/*', {base: 'dep/greenworks/'}
    .pipe gulp.dest path.join(paths.dist.dir, 'dep', 'greenworks')

gulp.task 'package-modules', ['package-launcher'], ->
  if process.platform == 'darwin'
    resourcesDir = paths.dist.app.resources.mac
  else
    resourcesDir = paths.dist.app.resources.others

  gulp.src 'node_modules/**/*'
    .pipe gulp.dest path.join(resourcesDir, 'node_modules')

gulp.task 'run', ['download-electron'], ->
  if process.platform == 'darwin'
    app = paths.dist.app.executable.mac
  else
    app = paths.dist.app.executable.others

  spawn "../#{app}", [],
    cwd: path.resolve paths.dist.dir
    stdio: 'inherit'

  return
