angular.module('triton_note.config', [])
.constant 'serverURL', 'https://triton_note.fathens.org'

.config ($stateProvider, $urlRouterProvider) ->
	$stateProvider
	.state 'home',
		url: '/list'
		templateUrl: 'page/list.html'
		controller: 'ListReportsCtrl'

	.state 'show-report',
		url: '/show-report?index'
		templateUrl: 'page/report/show.html'
		controller: 'ShowReportCtrl'

	.state 'edit-report',
		url: '/edit-report'
		templateUrl: 'page/report/edit.html'
		controller: 'EditReportCtrl'

	.state 'add-report',
		url: '/add-report'
		templateUrl: 'page/report/add.html'
		controller: 'AddReportCtrl'

	.state 'view-on-map',
		url: '/view-on-map?edit'
		templateUrl: 'page/report/view-on-map.html'
		controller: 'ReportOnMapCtrl'
		onExit: (GMapFactory) -> GMapFactory.clear()

	.state 'distribution-map',
		url: '/distribution-map'
		templateUrl: 'page/menu/distribution-map.html'
		controller: 'DistributionMapCtrl'
		onExit: (GMapFactory) -> GMapFactory.clear()

	.state 'preferences',
		url: '/preferences'
		templateUrl: 'page/menu/preferences.html'
		controller: 'PreferencesCtrl'

	.state 'sns',
		url: '/sns'
		templateUrl: 'page/menu/sns.html'
		controller: 'SNSCtrl'

	.state 'privacy',
		url: '/privacy'
		templateUrl: 'page/privacy.html'

	.state 'acceptance',
		url: '/acceptance'
		templateUrl: 'page/acceptance.html'
		controller: 'AcceptanceCtrl'

	$urlRouterProvider
	.when '', ($state, AcceptanceFactory) ->
		console.log "Acceptance Checking on #{angular.toJson $state.current}"
		v = AcceptanceFactory.isReady()
		console.log "Acceptance = #{v}"
		if v then '/list' else '/acceptance'
