require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic'])
.run ($log, LocalStorageFactory) !->
	ionic.Platform.ready !->
		$log.info "Device is ready"
		StatusBar.styleDefault! if (window.StatusBar)
