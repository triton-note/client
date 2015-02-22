require! {
	fs
	gulp
	'main-bower-files'
	'event-stream': es
	'prelude-ls': _
}
gp = require('gulp-load-plugins')!

project-name = 'TritonNote'

isRelease = gp.util.env.release?

app-src = "./www-src"
app-dst = "./www"
mkPath = (src-name, dst-name = src-name) ->
	dir = "#{app-src}/#{src-name}" if src-name != null
	(...ext) ->
		src-dir: dir
		dst-dir: "#{app-dst}/#{dst-name}"
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
		.pipe gulp.dest paths.image.dst-dir

gulp.task "livescript", ->
	es.concat.apply null,
		findFolders(paths.ls.src-dir).map (folder) ->
			dir = "#{paths.ls.src-dir}/#{folder}"
			gulp.src ["#{dir}/_Main.ls", "#{dir}/**/!(_)*.ls"]
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

gulp.task "splash", ->
	android = gulp.src "resources/android/splash/**/*.9.png"
		.pipe gulp.dest "platforms/android/res"
	ios = gulp.src "resources/ios/splash/**/*.png"
		.pipe gulp.dest "platforms/ios/#{project-name}/Resources/splash"
	es.concat.apply null,
		[android, ios]

gulp.task "watch", !->
	gulp.watch paths.jade, ["jade"]
	gulp.watch paths.image, ["image"]
	gulp.watch paths.sass, ["sass"]
	gulp.watch paths.ls, ["livescript"]

gulp.task "clean", !->
	gulp.src app-dst, read: false
		.pipe gp.clean!

gulp.task "default", ["jade", "image", "sass", "livescript"]
