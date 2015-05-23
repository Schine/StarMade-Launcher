'use strict'

async = require('async')
mkdirp = require('mkdirp')
ncp = require('ncp')
gulp = require('gulp')
gutil = require('gulp-util')
path = require('path')
plugins = require('gulp-load-plugins')()
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
    electron:
      dir: 'dep/electron'
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


pkg = require(paths.package)
electronVersion = pkg.electronVersion

gulp.task 'default', ['run']

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

gulp.task 'jade', ->
  gulp.src paths.static.jade.glob
    .pipe plugins.jade
      pretty: true
    .pipe gulp.dest paths.build.dir

gulp.task 'less', ->
  gulp.src paths.static.styles.main
    .pipe plugins.less()
    .pipe gulp.dest paths.build.styles.dir

gulp.task 'package', ['coffee', 'jade', 'less', 'download-electron'], (callback) ->
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

      callback()

  return

gulp.task 'run', ['download-electron', 'package'], ->
  if process.platform == 'darwin'
    app = paths.dist.app.executable.mac
  else
    app = paths.dist.app.executable.others

  spawn app, [],
    stdio: 'inherit'

  return
