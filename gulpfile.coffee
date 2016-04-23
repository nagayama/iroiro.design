browserSync = require('browser-sync').create()
runSequence = require('run-sequence')
del         = require('del')
webpack     = require('webpack-stream')

gulp       = require('gulp')
util       = require('gulp-util')
gulpif     = require('gulp-if')
data       = require('gulp-data')
jade       = require('gulp-jade')
scss       = require('gulp-sass')
postcss    = require('gulp-postcss')
csso       = require('gulp-csso')
imagemin   = require('gulp-imagemin')
sourcemaps = require('gulp-sourcemaps')
ghpages    = require('gulp-gh-pages')

dir =
  build: "./build/"
  src:   "./src/"

is_development = util.env.development

gulp.task 'jade', ->
  gulp
    .src [dir.src+"**/*.jade", "!" + dir.src+"**/_*.jade"]
    .pipe data ()->
      if is_development
        require("./data/development.json")
      else
        require("./data/production.json")
    .pipe jade(
      #pretty: true
    )
    .pipe gulp.dest dir.build

gulp.task 'scss', ->
  gulp
    .src dir.src+"styles/main.scss"
    .pipe gulpif(is_development, sourcemaps.init())
    .pipe scss()
    .pipe postcss [
      require('autoprefixer')(browsers: ['last 3 versions'])
    ]
    .pipe gulpif(!is_development, csso())
    .pipe gulpif(is_development, sourcemaps.write("."))
    .pipe gulp.dest dir.build+"styles/"
    .pipe browserSync.stream(match: "**/*.css")

gulp.task 'webpack', ->
  gulp
    .src dir.src+"scripts/main.js"
    .pipe webpack
      devtool: 'source-map'
      recursive: true
      output:
        filename: "main.js"
      module:
        loaders: [
          test: /\.js$/, exclude: /node_modules/, loader: "babel-loader"
        ]
      resolve:
        extentions: ["", ".js"]
    .pipe gulp.dest dir.build+"scripts/"
  
gulp.task 'images', ->
  gulp
    .src dir.src+"images/**/*"
    .pipe imagemin
      optimizationLevel: 7
      progressive: true
      interlaced: true
      multipass: true
    .pipe gulp.dest dir.build+"images"

gulp.task 'watch', ['build'], ->
  browserSync.init
    server: dir.build
    files: [
      dir.build+"**/*.html"
      dir.build+"**/*.js"
      dir.build+"images/**/*"
    ]

  gulp.watch dir.src + "**/*.jade",     ['jade']
  gulp.watch dir.src + "**/*.scss",     ['scss']
  gulp.watch dir.src + "**/*.coffee",   ['webpack']
  gulp.watch dir.src + "features/**/*", ['images']

gulp.task 'clean', ->
  del.sync dir.build

gulp.task 'deploy', ['build'], ->
  gulp
    .src dir.build + "**/*"
    .pipe ghpages()

gulp.task 'build', ->
  runSequence 'clean', ['scss', 'webpack', 'images', 'jade']

gulp.task 'default', ->
  gulp.start 'build'

