require! {
	fs
	gulp
	es: 'event-stream'
	_: 'prelude-ls'
}
gp = require('gulp-load-plugins')()

isRelease = gp.util.env.release?

mkPath = (dir) -> (...ext) -> ext.map (a) -> "./www-src/#{dir}/**/!(_)*.#{a}"
paths =
	jade: mkPath('') 'jade'
	image: mkPath('img') 'png', 'jpg'
	sass: mkPath('sass') 'scss', 'sass'
	ls: "./www-src/ls"

findFolders = (dir) ->
	fs.readdirSync(dir).filter (file) ->
		fs.statSync("#{dir}/#{file}").isDirectory!

gulp.task "ionic", ->
	es.concat.apply null, [
		gulp.src mkPath('**/fonts') '*'
			.pipe gulp.dest "./www"

		gulp.src mkPath('lib') 'bundle.js'
			.pipe gp.if isRelease, gp.ngmin!
			.pipe gp.if isRelease, gp.uglify!
			.pipe gulp.dest "./www/lib"

		gulp.src mkPath('lib') 'json'
			.pipe gulp.dest "./www/lib"
	]

gulp.task "jade", ->
	gulp.src paths.jade
		.pipe gp.jade {
			pretty: !isRelease
			compileDebug: !isRelease
		}
		.pipe gp.if isRelease, gp.minify-html!
		.pipe gulp.dest "./www"

gulp.task "image", ->
	gulp.src paths.image
		.pipe gp.if isRelease, gp.imagemin {
			optimizationLevel: 7
			progressive: true
		}
		.pipe gulp.dest "./www/img"

gulp.task "livescript", ->
	es.concat.apply null,
		findFolders(paths.ls).map (folder) ->
			gulp.src ["#{paths.ls}/#{folder}/Main.ls", "#{paths.ls}/#{folder}/**/*.ls"]
				.pipe gp.concat "#{folder}.ls"
				.pipe gp.livescript {
					base: true
					const: true
				}
				.pipe gp.if isRelease, gp.ngmin!
				.pipe gp.if isRelease, gp.uglify!
				.pipe gulp.dest "./www/js"

gulp.task "sass", ->
	gulp.src paths.sass
		.pipe gp.sass!
		.pipe gp.if isRelease, gp.minify-css!
		.pipe gulp.dest "./www/css/"

gulp.task "bower", ->
	gp.bower-files!
		.pipe gp.if isRelease, gp.uglify {
			preserveComments: "some"
		}
		.pipe gp.flatten!
		.pipe gulp.dest "./www/lib"

gulp.task "watch", !->
	gulp.watch paths.jade, ["jade"]
	gulp.watch paths.image, ["image"]
	gulp.watch paths.sass, ["sass"]
	gulp.watch paths.ls, ["livescript"]

gulp.task "default", ["jade", "image", "sass", "livescript", "ionic"]
