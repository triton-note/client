fs = require 'fs'
gulp = require 'gulp'
del = require 'del'
es = require 'event-stream'
gp = require('gulp-load-plugins')()

isRelease = gp.util.env.release?

app_src = "./www-src"
app_dst = "./www"
mkPath = (src_name, dst_name = src_name) ->
	dir = "#{app_src}/#{src_name}" if src_name != null
	(ext...) ->
		src_dir: dir
		dst_dir: "#{app_dst}/#{dst_name}"
		src: if dir then ext.map (a) -> "#{dir}/**/!(_)*.#{a}"
paths =
	jade: mkPath('') 'jade'
	image: mkPath('img') 'png', 'jpg'
	sass: mkPath('sass', 'css') 'scss', 'sass'
	script: mkPath('script', 'js')()
	bower: mkPath(null, 'lib')()

findFolders = (dir) ->
	fs.readdirSync(dir).filter (file) ->
		fs.statSync("#{dir}/#{file}").isDirectory()

gulp.task "jade", ->
	gulp.src paths.jade.src
		.pipe gp.jade
			pretty: !isRelease
			compileDebug: !isRelease
		.pipe gp.if isRelease, gp.minifyHtml()
		.pipe gulp.dest paths.jade.dst_dir

gulp.task "image", ->
	gulp.src paths.image.src
		.pipe gulp.dest paths.image.dst_dir

gulp.task "coffeescript", ->
	es.concat.apply null,
		findFolders(paths.script.src_dir).map (folder) ->
			dir = "#{paths.script.src_dir}/#{folder}"
			gulp.src ["#{dir}/_Main.coffee", "#{dir}/**/!(_)*.coffee"]
				.pipe gp.concat "#{folder}.coffee"
				.pipe gp.coffee
					base: true
				.pipe gp.if isRelease, gp.ngmin()
				.pipe gp.if isRelease, gp.uglify()
				.pipe gulp.dest paths.script.dst_dir

gulp.task "sass", ->
	gulp.src paths.sass.src
		.pipe gp.sass()
		.pipe gp.if isRelease, gp.minifyCss()
		.pipe gulp.dest paths.sass.dst_dir

gulp.task "watch", !->
	gulp.watch paths.jade, ["jade"]
	gulp.watch paths.image, ["image"]
	gulp.watch paths.sass, ["sass"]
	gulp.watch paths.script, ["coffeescript"]

gulp.task "clean", (cb) ->
	del [app_dst], cb

gulp.task "bower", ->
	gp.bower 'www/lib'

gulp.task "build", ["bower"], ->
	gulp.start "jade", "image", "sass", "coffeescript"

gulp.task "default", ["clean"], ->
	gulp.start "build"
