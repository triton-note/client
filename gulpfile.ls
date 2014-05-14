require! {
	fs
	gulp
	es: 'event-stream'
	_: 'prelude-ls'
}
gp = require('gulp-load-plugins')!

isRelease = gp.util.env.release?

mkPath = (src-name, dst-name = src-name) ->
	dir = "./www-src/#{src-name}" if src-name != null
	(...ext) ->
		src-dir: dir
		dst-dir: "./www/#{dst-name}"
		src: if dir then ext.map (a) -> "#{dir}/**/!(_)*.#{a}"
paths =
	jade: mkPath('') 'jade'
	image: mkPath('img') 'png', 'jpg'
	sass: mkPath('sass', 'css') 'scss', 'sass'
	ls: mkPath('ls', 'js')!
	bower: mkPath(null, 'lib')!

findFolders = (dir) ->
	fs.readdirSync(dir).filter (file) ->
		fs.statSync("#{dir}/#{file}").isDirectory!

gulp.task "ionic", ->
	fonts = ->
		path = mkPath('**/fonts', '') '*'
		gulp.src path.src
			.pipe gulp.dest path.dst-dir
	js = ->
		path = mkPath('lib') 'bundle.js'
		gulp.src path.src
			.pipe gp.if isRelease, gp.ngmin!
			.pipe gp.if isRelease, gp.uglify!
			.pipe gulp.dest path.dst-dir
	json = ->
		path = mkPath('lib') 'json'
		gulp.src path.src
			.pipe gulp.dest path.dst-dir

	es.concat.apply null, [fonts!, js!, json!]

gulp.task "jade", ->
	gulp.src paths.jade.src
		.pipe gp.jade {
			pretty: !isRelease
			compileDebug: !isRelease
		}
		.pipe gp.if isRelease, gp.minify-html!
		.pipe gulp.dest paths.jade.dst-dir

gulp.task "image", ->
	gulp.src paths.image.src
		.pipe gp.imagemin {
			optimizationLevel: 7
			progressive: true
		}
		.pipe gulp.dest paths.image.dst-dir

gulp.task "livescript", ->
	es.concat.apply null,
		findFolders(paths.ls.src-dir).map (folder) ->
			dir = "#{paths.ls.src-dir}/#{folder}"
			gulp.src ["#{dir}/Main.ls", "#{dir}/**/*.ls"]
				.pipe gp.concat "#{folder}.ls"
				.pipe gp.livescript {
					base: true
					const: true
				}
				.pipe gp.if isRelease, gp.ngmin!
				.pipe gp.if isRelease, gp.uglify!
				.pipe gulp.dest paths.ls.dst-dir

gulp.task "sass", ->
	gulp.src paths.sass.src
		.pipe gp.sass!
		.pipe gp.if isRelease, gp.minify-css!
		.pipe gulp.dest paths.sass.dst-dir

gulp.task "bower", ->
	gp.bower-files!
		.pipe gp.if isRelease, gp.uglify {
			preserveComments: "some"
		}
		.pipe gp.flatten!
		.pipe gulp.dest paths.bower.dst-dir

gulp.task "watch", !->
	gulp.watch paths.jade, ["jade"]
	gulp.watch paths.image, ["image"]
	gulp.watch paths.sass, ["sass"]
	gulp.watch paths.ls, ["livescript"]

gulp.task "default", ["jade", "image", "sass", "livescript", "ionic"]
