require! {
	_: 'prelude-ls'
}

angular.module('Fish', ['ionic'])
.run ($ionicPlatform, $http, PostFormFactory, LoginFactory) !->
	$ionicPlatform.ready !->
		StatusBar.styleDefault! if (window.StatusBar)
		LoginFactory.getToken handleToken, (err) !-> alert "Error: #{err}"

	$http.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
	$http.defaults.transformRequest = [PostFormFactory.transform]

	handleToken = (token) !->
		alert "Access token: #{token}"