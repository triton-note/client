require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic'])
.run ($ionicPlatform, $http, PostFormFactory) !->
	$ionicPlatform.ready !->
		StatusBar.styleDefault! if (window.StatusBar)

	$http.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
	$http.defaults.transformRequest = [PostFormFactory.transform]
