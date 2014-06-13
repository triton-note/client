require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic'])
.run ($ionicPlatform, $http, PostFormFactory, AcceptanceFactory, AccountFactory, LocalStorageFactory) !->
	$ionicPlatform.ready !->
		StatusBar.styleDefault! if (window.StatusBar)
		AcceptanceFactory.obtain !-> AccountFactory.ticket.get!

	$http.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
	$http.defaults.transformRequest = [PostFormFactory.transform]
