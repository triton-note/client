require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic'])
.run ($log, $ionicPlatform, $rootScope, $http, PostFormFactory, AcceptanceFactory, AccountFactory, LocalStorageFactory) !->
	$ionicPlatform.ready !->
		StatusBar.styleDefault! if (window.StatusBar)
		AcceptanceFactory.obtain !->
			$log.info "Acceptance obtained"
			$rootScope.$broadcast 'fathens-reports-changed'
