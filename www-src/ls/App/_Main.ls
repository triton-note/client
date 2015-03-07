require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic', 'monospaced.elastic'])
.run ($log, GMapFactory) !->
	ionic.Platform.ready !->
		$log.info "Device is ready"
		StatusBar.hide!
		ionic.Platform.fullScreen!
