.constant 'serverURL', 'https://triton-note.fathens.org'

.config ($stateProvider, $urlRouterProvider) !->
	$stateProvider
	.state 'main',
		url: '/'
		templateUrl: 'page/main.html'
		controller: 'ShowReportsCtrl'

	.state 'show-report',
		url: '/show-report/:index'
		templateUrl: 'page/report/show.html'
		controller: 'DetailReportCtrl'

	.state 'edit-report',
		url: '/show-report/:index'
		templateUrl: 'page/report/edit.html'
		controller: 'EditReportCtrl'

	.state 'new-report',
		url: '/new-report/:init'
		templateUrl: 'page/report/add.html'
		controller: 'AddReportCtrl'

	.state 'edit-on-map',
		url: '/edit-on-map/:previous'
		templateUrl: 'page/edit-on-map.html'
		controller: 'EditReportGMapCtrl'

	.state 'distribution-map',
		url: '/distribution-map'
		templateUrl: 'page/menu/distribution-map.html'
		controller: 'DistributionMapCtrl'

	.state 'preferences',
		url: '/preferences'
		templateUrl: 'page/menu/preferences.html'
		controller: 'PreferencesCtrl'

	.state 'sns',
		url: '/sns'
		templateUrl: 'page/menu/sns.html'
		controller: 'SNSCtrl'

	$urlRouterProvider.otherwise('/')
