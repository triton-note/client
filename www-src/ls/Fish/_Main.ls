angular.module('Fish', ['ionic'])
.run ($ionicPlatform) !->
	$ionicPlatform.ready !->
		StatusBar.styleDefault! if (window.StatusBar)
