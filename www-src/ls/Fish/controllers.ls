.controller 'MenuCtrl', ($log, $scope) !->
	$scope.openMap = !-> alert "Open Map"

.controller 'AcceptanceCtrl', ($log, $scope, AcceptanceFactory) !->
	$scope.terms = AcceptanceFactory.terms-of-use!

.controller 'ShowReportsCtrl', ($log, $scope, $ionicModal, $ionicPopup, ReportFactory, GMapFactory) !->
	$ionicModal.fromTemplateUrl 'template/show-report.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.showMap = !->
		GMapFactory.showMap $scope.report.location.geoinfo

	$scope.reports = []
	$scope.hasMoreReports = false
	$scope.clear = !->
		$scope.reports = []
		$scope.hasMoreReports = true
	$scope.moreReports = !->
		last-id = $scope.reports[$scope.reports.length - 1]?.id ? null
		ReportFactory.load last-id, (more) !->
			$scope.hasMoreReports = ! _.empty more
			$log.info "Set hasMoreReports = #{$scope.hasMoreReports}"
			$scope.reports = $scope.reports ++ more
			$scope.$broadcast 'scroll.infiniteScrollComplete'
	$scope.$on 'fathens-reports-changed', (event, args) !->
		$scope.clear!

	$scope.detail = (index) !->
		$scope.index = index
		$scope.report = $scope.reports[index]
		$scope.modal.show!

	$scope.delete = (index) !->
		$ionicPopup.confirm do
			title: "Delete Report"
			template: "Are you sure to delete this report ?"
		.then (res) !-> if res
			ReportFactory.remove $scope.reports[index].id, !->
				$scope.reports.splice index, 1
				$scope.$broadcast 'fathens-reports-changed'
			$scope.modal.hide!

	$scope.close = !-> $scope.modal.hide!

.controller 'EditReportCtrl', ($log, $filter, $scope, $rootScope, $ionicModal, ReportFactory, GMapFactory) !->
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
			$rootScope.$broadcast 'fathens-reports-changed'
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
		photo: uri
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
						$log.error "Failed to infer: #{error}"
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
			$rootScope.$broadcast 'fathens-reports-changed'
		$scope.modal.hide!

.controller 'AddFishCtrl', ($scope, $ionicPopup) !->
	# $scope.report.fishes
	$scope.deleteFish = (index) !-> $scope.report.fishes.splice index, 1
	$scope.addFish = !->
		$scope.fish = {
			name: null
			count: 1
			length:
				unit: 'cm'
			weight:
				unit: 'kg'
		}
		$ionicPopup.show {
			title: 'Add Fish'
			templateUrl: "add-fish"
			scope: $scope
			buttons:
				*text: "Cancel"
					type: "button-default"
					onTap: (e) -> null
				*text: "OK"
					type: "button-positive"
					onTap: (e) !->
						if $scope.fish.name?.length > 0 && $scope.fish.count > 0
						then
							if ! $scope.fish.length.value then $scope.fish.length = null
							if ! $scope.fish.weight.value then $scope.fish.weight = null
							return $scope.fish
						else e.preventDefault!
		}
		.then (res) !-> $scope.report.fishes.push res if res
			, (err) !-> alert "Error: #err"
			, (msg) !-> alert "Message: #msg"
