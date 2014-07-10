.controller 'MapCtrl', ($log, $scope) !->
	$scope.open = !-> alert "Open Map"

.controller 'SettingsCtrl', ($log, $scope, $ionicModal, UnitFactory) !->
	$ionicModal.fromTemplateUrl 'template/settings.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'
	$scope.open = !->
		clear!
		$scope.modal.show!
	$scope.cancel = !->
		$scope.modal.hide!
	$scope.submit = !->
		UnitFactory.save $scope.settings.unit
		$scope.modal.hide!

	clear = !->
		$scope.units = UnitFactory.units!
		UnitFactory.load (units) !->
			$scope.settings =
				unit: units

.controller 'ShowReportsCtrl', ($log, $scope, $ionicModal, $ionicPopup, ReportFactory, GMapFactory) !->
	$ionicModal.fromTemplateUrl 'template/show-report.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.showMap = !->
		GMapFactory.showMap $scope.report.location.geoinfo

	$scope.reports = ReportFactory.cachedList
	$scope.hasMoreReports = ReportFactory.hasMore
	$scope.refresh = !->
		ReportFactory.refresh !->
			$scope.$broadcast 'scroll.refreshComplete'
	$scope.moreReports = !->
		ReportFactory.load !->
			$scope.$broadcast 'scroll.infiniteScrollComplete'
	ionic.Platform.ready !->
		$scope.$apply ReportFactory.clear

	$scope.detail = (index) !->
		$scope.index = index
		$scope.report = ReportFactory.getReport index
		$scope.modal.show!

	$scope.delete = (index) !->
		$ionicPopup.confirm do
			title: "Delete Report"
			template: "Are you sure to delete this report ?"
		.then (res) !-> if res
			ReportFactory.remove index, !->
				$log.debug "Remove completed."
			$scope.modal.hide!

	$scope.close = !-> $scope.modal.hide!

.controller 'EditReportCtrl', ($log, $filter, $scope, $rootScope, $ionicModal, $ionicListDelegate, ReportFactory, GMapFactory) !->
	# $scope.report = 表示中のレコード
	# $scope.index = 表示中のレコードの index
	$ionicModal.fromTemplateUrl 'template/edit-report.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.title = "Edit Report"

	$scope.showMap = !->
		GMapFactory.showMap $scope.report.location.geoinfo, (gi) !->
			$scope.report.location.geoinfo = gi

	$scope.editOnList = (index) !->
		$ionicListDelegate.closeOptionButtons!
		$scope.index = index
		$scope.report = ReportFactory.getReport index
		$scope.edit!

	$scope.edit = !->
		$scope.currentReport = angular.copy $scope.report
		$scope.report.dateAt = $filter('date') new Date($scope.report.dateAt), 'yyyy-MM-dd'
		$scope.modal.show!

	$scope.cancel = !->
		angular.copy $scope.currentReport, $scope.report
		$scope.modal.hide!
	
	$scope.submit = !->
		$scope.currentReport = null
		ReportFactory.update $scope.report, !->
			$log.debug "Edit completed."
		$scope.modal.hide!

.controller 'AddReportCtrl', ($log, $filter, $scope, $rootScope, $ionicModal, $ionicPopup, PhotoFactory, ReportFactory, GMapFactory, SessionFactory, LocalStorageFactory) !->
	$ionicModal.fromTemplateUrl 'template/edit-report.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.title = "New Report"
	$scope.publish =
		do: {}
		ables: []

	newReport = (uri, geoinfo) ->
		photo:
			mainview: uri
		dateAt: $filter('date') new Date!, 'yyyy-MM-dd'
		location:
			name: "Here"
			geoinfo: geoinfo
		fishes: []
		comment: ""

	$scope.open = !->
		start = (geoinfo = null) !->
			SessionFactory.start geoinfo
			, !->
				PhotoFactory.select (uri) !->
					SessionFactory.put-photo uri, (inference) !->
						$scope.$apply !->
							$scope.report.photo = inference.url
							if inference.location
								$scope.report.location.name = that
							if inference.fishes && inference.fishes.length > 0
								$scope.report.fishes = inference.fishes
					, (error) !->
						$ionicPopup.alert do
							title: "Failed to upload"
							template: error
						.then (res) !->
							$scope.modal.hide!
					$scope.$apply !->
						$scope.publish.ables = if LocalStorageFactory.login-way.load! then [that] else []
						imageUrl = if device.platform == 'Android'
							then ""
							else uri
						$scope.report = newReport imageUrl, geoinfo
					$scope.modal.show!
				, (msg) !->
					$ionicPopup.alert do
						title: "No photo selected"
						template: "Need a photo to report"
			, (error) !->
				$ionicPopup.alert do
					title: "Error"
					template: error
		navigator.geolocation.getCurrentPosition do
			(pos) !->
				$log.debug "Gotta geolocation: #{angular.toJson pos}"
				start do
					latitude: pos.coords.latitude
					longitude: pos.coords.longitude
			, (error) !->
				$log.error "Geolocation Error: #{angular.toJson error}"
				start!

	$scope.showMap = !->
		GMapFactory.showMap $scope.report.location.geoinfo, (gi) !->
			$scope.report.location.geoinfo = gi

	$scope.cancel = !-> $scope.modal.hide!
	$scope.submit = !->
		report = angular.copy $scope.report
		report.dateAt = new Date(report.dateAt).getTime!
		SessionFactory.finish report, [name for name, value of $scope.publish.do when value][0], !->
			$log.debug "Success on submitting report"
		$scope.modal.hide!

.controller 'AddFishCtrl', ($scope, $ionicPopup, UnitFactory) !->
	# $scope.report.fishes
	fish-template = (o = null) ->
		r =
			name: null
			count: 1
		r <<< o if o
		r.length = {} unless r.length
		r.weight = {} unless r.weight
		UnitFactory.load (units) !->
			r.length.unit = units.length
			r.weight.unit = units.weight
		r
	buttons =
		cancel:
			text: "Cancel"
			type: "button-default"
			onTap: (e) -> null
		ok:
			text: "OK"
			type: "button-positive"
			onTap: (e) !->
				if $scope.tmpFish.name?.length > 0 && $scope.tmpFish.count > 0
				then
					if ! $scope.tmpFish.length.value then $scope.tmpFish.length = null
					if ! $scope.tmpFish.weight.value then $scope.tmpFish.weight = null
					return $scope.tmpFish
				else e.preventDefault!
	show = (func, ...bs) !->
		$ionicPopup.show {
			templateUrl: "add-fish"
			scope: $scope
			buttons: bs
		}
		.then (res) !->
			func res if res

	$scope.units = UnitFactory.units!
	$scope.addFish = !->
		$scope.tmpFish = fish-template!
		show (fish) !-> $scope.report.fishes.push fish
		,buttons.cancel, buttons.ok
	$scope.deleteFish = (index) !->
		$scope.report.fishes.splice index, 1
	$scope.editFish = (index) !->
		$scope.tmpFish = fish-template $scope.report.fishes[index]
		del =
			text: "Delete"
			type: "button-outline button-assertive"
			onTap: (e) ->
				$ionicPopup.confirm do
					template: "Are you sure to delete this catch ?"
				.then (res) !-> if res
					$scope.deleteFish index
		show (fish) !-> angular.copy(fish, $scope.report.fishes[index])
		,buttons.cancel, del, buttons.ok
