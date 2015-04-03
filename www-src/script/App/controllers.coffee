angular.module('triton_note.controllers', [])
.controller 'AcceptanceCtrl', ($log, $scope, $state, $stateParams, $ionicHistory, $ionicLoading, $ionicPopup, AcceptanceFactory) ->
	$ionicLoading.show()
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter AcceptanceCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.accept = ->
			$log.info "Acceptance obtained"
			AcceptanceFactory.success()
			$ionicHistory.nextViewOptions
				disableAnimate: true
				disableBack: true
			$state.go 'home'

.controller 'SNSCtrl', ($log, $scope, $stateParams, $ionicHistory, $ionicLoading, $ionicPopup, AccountFactory, ReportFactory) ->
	$ionicLoading.show()
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter SNSCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		AccountFactory.get_username (username) ->
			$scope.$apply -> $scope.done username
		, (error_msg) ->
			$scope.$apply -> $scope.done()

	$scope.checkSocial = ->
		$ionicLoading.show()
		next = $scope.social.username is null
		$log.debug "Changing social: #{next}"
		on_error = (error) ->
			$log.error "Erorr on Facebook: #{angular.toJson error}"
			$scope.done $scope.social.username
			$ionicPopup.alert
				title: "Rejected"
		if next
			AccountFactory.connect $scope.done, on_error
		else
			AccountFactory.disconnect ->
				ReportFactory.clear_list()
				$ionicHistory.clearCache()
				$log.warn "SNSCtrl: Cache Cleared()"
				$scope.done()
				$ionicPopup.alert
					title: "No social connection"
					template: "Please login to Facebook, if you want to continue this app."
			, on_error
	$scope.done = (username = null) ->
		$scope.social =
			username: username
			login: username isnt null
		$ionicLoading.hide()
		$log.debug "Account connection: #{angular.toJson $scope.social}"

.controller 'PreferencesCtrl', ($log, $scope, $stateParams, $ionicSideMenuDelegate, $ionicLoading, $ionicPopup, UnitFactory) ->
	$ionicLoading.show()
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter PreferencesCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$ionicLoading.show()
		UnitFactory.load (units) ->
			$scope.unit = units
			$ionicLoading.hide()

	$scope.submit = ->
		UnitFactory.save $scope.unit
		$ionicSideMenuDelegate.toggle_left true
	$scope.units = UnitFactory.units()

.controller 'ListReportsCtrl', ($log, $scope, ReportFactory) ->
	$scope.reports = ReportFactory.cachedList
	$scope.hasMoreReports = ReportFactory.hasMore
	$scope.refresh = ->
		$log.debug "Refresh Reports List ..."
		ReportFactory.refresh ->
			$scope.$broadcast 'scroll.refreshComplete'
	$scope.moreReports = -> if ReportFactory.hasMore()
		$log.debug "Get More Reports List ..."
		ReportFactory.load ->
			$scope.$broadcast 'scroll.infiniteScrollComplete'

.controller 'ShowReportCtrl', ($log, $timeout, $state, $stateParams, $ionicHistory, $ionicScrollDelegate, $scope, $ionicPopover, $ionicPopup, ReportFactory, ConditionFactory) ->
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter ShowReportCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.popover = {}
		['show_location', 'option_buttons'].forEach (name) ->
			$ionicPopover.fromTemplateUrl name,
				scope: $scope
			.then (popover) ->
				$scope.popover[_.camelize name] = popover
		$scope.popover_hide = ->
			for _, p of $scope.popover
				p.hide()

		$scope.should_clear = true
		if $stateParams.index and ReportFactory.current().index is null
			$scope.report = ReportFactory.getReport($scope.index = Number($stateParams.index))
		else
			c = ReportFactory.current()
			$scope.index = c.index
			$scope.report = c.report
		$scope.tide_icon = ConditionFactory.tide_phases.filter((v) -> v.name is $scope.report.condition?.tide).map((v) -> v.icon)[0]
		$scope.moon_icon = ConditionFactory.moon_phases[$scope.report.condition?.moon]
		
		$scope.show_location_gmap =
			center: new google.maps.LatLng($scope.report.location.geoinfo.latitude, $scope.report.location.geoinfo.longitude)
			map: null
			marker: null
		
		$log.debug "Show Report: #{angular.toJson $scope.report}"
		$ionicScrollDelegate.$getByHandle("scroll_img_show_report").zoomTo 1

	$scope.$on '$ionicView.beforeLeave', (event, state) ->
		$log.debug "Before Leave ShowReportCtrl: event=#{angular.toJson event}"
		ReportFactory.clear_current() if $scope.should_clear
		for _, p of $scope.popover
			p?.remove()
		$scope.show_location_gmap.map = null
		$scope.show_location_gmap.marker = null

	$scope.preview_map = ($event) ->
		gmap = $scope.show_location_gmap
		$scope.popover.show_location.show $event
		.then ->
			div = document.getElementById "show_gmap"
			unless gmap.map
				gmap.map = new google.maps.Map div,
					mapTypeId: google.maps.MapTypeId.HYBRID
					disableDefaultUI: true
			gmap.map.setCenter gmap.center
			gmap.map.setZoom 8

			gmap.marker?.setMap null
			gmap.marker = new google.maps.Marker
				title: $scope.report.location.name
				map: gmap.map
				position: gmap.center
				animation: google.maps.Animation.DROP

			google.maps.event.addDomListener div, 'click', ->
				$scope.use_current()
				$state.go "view_on_map"

	$scope.useCurrent = ->
		$scope.should_clear = false
	$scope.delete = ->
		$scope.popover_hide()
		$ionicPopup.confirm
			title: "Delete Report"
			template: "Are you sure to delete this report ?"
		.then (res) -> if res
			ReportFactory.remove $scope.index, ->
				$log.debug "Remove completed."
			$ionicHistory.goBack()
	$scope.publish = ->
		$scope.popover_hide()
		$ionicPopup.confirm
			title: "Publish Report"
			template: "Are you sure to post this report to Facebook ?"
		.then (res) -> if res
			ReportFactory.publish $scope.report.id, ->
				$log.debug "Publish completed."
				$ionicPopup.alert
					title: 'Completed to post'
			, (error) ->
				$ionicPopup.alert
					title: 'Error'
					template: "Failed to post"

.controller 'EditReportCtrl', ($log, $stateParams, $scope, $ionicScrollDelegate, $ionicHistory, $ionicLoading, ReportFactory) ->
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter EditReportCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.should_clear = true
		$scope.report = ReportFactory.current().report
		$ionicScrollDelegate.$getByHandle("scroll_img_edit_report").zoomTo 1

	$scope.$on '$ionicView.beforeLeave', (event, state) ->
		$log.debug "Before Leave EditReportCtrl: event=#{angular.toJson event}"
		ReportFactory.clear_current() if $scope.should_clear

	$scope.useCurrent = ->
		$scope.should_clear = false
	$scope.submit = ->
		$ionicLoading.show()
		ReportFactory.updateByCurrent ->
			$log.debug "Edit completed."
			$ionicHistory.goBack()
		, $ionicLoading.hide
	$scope.submission_enabled = ->
		!!$scope.report?.location?.name

.controller 'AddReportCtrl', ($log, $timeout, $ionicPlatform, $scope, $stateParams, $ionicHistory, $ionicLoading, $ionicPopover, $ionicPopup, PhotoFactory, SessionFactory, ReportFactory, GMapFactory, ConditionFactory) ->
	$log.debug "Init AddReportCtrl"
	$ionicLoading.show()
	$scope.$on '$ionicView.loaded', (event, state) ->
		$log.debug "Loaded AddReportCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"

		$ionicPopover.fromTemplateUrl 'confirm_submit',
			scope: $scope
		.then (popover) ->
			$scope.confirm_submit = popover

	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter AddReportCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.should_clear = true

		if ReportFactory.current().report
			$ionicLoading.hide()
			$scope.report = that
			$log.debug "Getting current report: #{angular.toJson $scope.report}"
			$scope.submission.enabled = !!$scope.report.photo.original
		else
			on_error = (title) -> (error_msg) ->
				$ionicLoading.hide()
				$ionicPopup.alert
					title: title
					template: error_msg
				.then $ionicHistory.goBack
			store =
				photo: null
			PhotoFactory.select (photo) ->
				uri = URL.createObjectURL photo
				console.log "Selected photo info: #{uri}"
				$scope.report = ReportFactory.newCurrent uri
				$ionicLoading.hide()
				store.photo = photo
			, (info) ->
				console.log "Exif info: #{angular.toJson info}"
				upload = (geoinfo) ->
					$scope.report.dateAt = new Date(Math.round((info?.timestamp ? new Date()).getTime() / 1000) * 1000)
					$scope.report.location.geoinfo = geoinfo
					$log.debug "Created report: #{angular.toJson $scope.report}"
					SessionFactory.start geoinfo, ->
						SessionFactory.put_photo store.photo
						, (result) ->
							$log.debug "Get result of upload: #{angular.toJson result}"
							$scope.submission.enabled = true
							$timeout ->
								$log.debug "Updating photo url: #{angular.toJson result.url}"
								angular.copy result.url, $scope.report.photo
							, 100
						, (inference) ->
							$log.debug "Get inference: #{angular.toJson inference}"
							if inference.location
								$scope.report.location.name = that
							if inference.fishes?.length > 0
								$scope.report.fishes = inference.fishes
						, on_error "Failed to upload"
					, on_error "Error"
				if info?.geoinfo
					upload info.geoinfo
				else
					$log.warn "Getting current location..."
					GMapFactory.getGeoinfo upload, (error) ->
						$log.error "Geolocation Error: #{angular.toJson error}"
						upload
							latitude: 0
							longitude: 0
			, on_error "Need one photo"

	$scope.$on '$ionicView.beforeLeave', (event, state) ->
		$log.debug "Before Leave AddReportCtrl: event=#{angular.toJson event}"
		ReportFactory.clear_current() if $scope.should_clear

	$scope.useCurrent = ->
		$scope.should_clear = false
	$scope.submit = ->
		$ionicLoading.show()
		if !$scope.report.location.name
			$scope.report.location.name = "MySpot"
		SessionFactory.finish $scope.report, $scope.submission.publishing, ->
			$ionicHistory.goBack()
		, $ionicLoading.hide
	$scope.submission =
		enabled: false
		publishing: false

.controller 'ReportOnMapCtrl', ($log, $scope, $stateParams, $ionicHistory, $ionicPopover, GMapFactory, ReportFactory) ->
	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter ReportOnMapCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.report = ReportFactory.current().report
		GMapFactory.onDiv $scope, 'edit_map', (gmap) ->
			$scope.$on 'popover.hidden', ->
				gmap.setClickable true
			$scope.showViewOptions = (event) ->
				gmap.setClickable false
				$scope.popover_view.show event
			if $stateParams.edit
				$scope.geoinfo = $scope.report.location.geoinfo
				GMapFactory.onTap (geoinfo) ->
					$scope.geoinfo = geoinfo
					GMapFactory.put_marker geoinfo
		, $scope.report.location.geoinfo
		$scope.view =
			gmap:
				type: GMapFactory.getMapType()
				types: GMapFactory.getMapTypes()
		$scope.$watch 'view.gmap.type', (value) ->
			$log.debug "Changing 'view.gmap.type': #{angular.toJson value}"
			GMapFactory.setMapType value
		$ionicPopover.fromTemplateUrl 'view_map_view',
			scope: $scope
		.then (pop) ->
			$scope.popover_view = pop

	$scope.submit = ->
		if $scope.geoinfo
			$scope.report.location.geoinfo = that
		$ionicHistory.goBack()

.controller 'DistributionMapCtrl', ($log, $ionicPlatform, $scope, $state, $stateParams, $ionicSideMenuDelegate, $ionicPopover, $ionicLoading, GMapFactory, DistributionFactory, ReportFactory) ->
	$ionicLoading.show()
	$scope.$on '$ionicView.loaded', (event, state) ->
		$log.debug "Loaded DistributionMapCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$scope.view =
			others: false
			name: null
			gmap:
				type: GMapFactory.getMapType()
				types: GMapFactory.getMapTypes()
		$scope.$watch 'view.others', (value) ->
			$log.debug "Changing 'view.person': #{angular.toJson value}"
			$scope.map_distribution()
		$scope.$watch 'view.name', (value) ->
			$log.debug "Changing 'view.fish': #{angular.toJson value}"
			$scope.map_distribution()
		$scope.$watch 'view.gmap.type', (value) ->
			$log.debug "Changing 'view.gmap.type': #{angular.toJson value}"
			GMapFactory.setMapType value
		$ionicPopover.fromTemplateUrl 'distribution_map_options',
			scope: $scope
		.then (pop) ->
			$scope.popover_options = pop
		$scope.showOptions = (event) ->
			$scope.gmap.setClickable false
			$scope.popover_options.show event
		$ionicPopover.fromTemplateUrl 'distribution_map_view',
			scope: $scope
		.then (pop) ->
			$scope.popover_view = pop
		$scope.showViewOptions = (event) ->
			$scope.gmap.setClickable false
			$scope.popover_view.show event
		$scope.$on 'popover.hidden', ->
			$scope.gmap.setClickable true

		icons = [1..9].map (count) ->
			size = 32
			center = size / 2
			r = ->
				min = 4
				max = center - 1
				v = min + (max - min) * count / 10
				_.min max, v
			canvas = document.createElement 'canvas'
			canvas.width = size
			canvas.height = size
			context = canvas.getContext '2d'
			context.beginPath()
			context.strokeStyle = "rgb(80, 0, 0)"
			context.fillStyle = "rgba(255, 40, 0, 0.7)"
			context.arc center, center, r(), 0, _.pi * 2, true
			context.stroke()
			context.fill()
			canvas.toDataURL()
		$scope.map_distribution = -> if gmap = $scope.gmap
			others = $scope.view.others
			fish_name = $scope.view.name
			map_mine = (list) ->
				$log.debug "Mapping my distribution (filtered by '#{fish_name}'): #{list}"
				gmap.clear()
				detail = (fish) -> (marker) ->
					marker.on plugin.google.maps.event.INFO_CLICK, ->
						$log.debug "Detail for fish: #{angular.toJson fish}"
						find_or = (fail) ->
							index = ReportFactory.getIndex fish.report_id
							if index >= 0
								GMapFactory.clear()
								$state.go 'show_report',
									index: index
							else fail()
						find_or ->
							ReportFactory.refresh ->
								find_or ->
									$log.error "Report not found by id: #{fish.report_id}"
				for fish in list
					gmap.addMarker
						title: "#{fish.name} x #{fish.count}"
						snippet: fish.date.toLocaleDateString()
						position:
							lat: fish.geoinfo.latitude
							lng: fish.geoinfo.longitude
						, detail fish
			map_others = (list) ->
				$log.debug "Mapping other's distribution (filtered by '#{fish_name}'): #{list}"
				gmap.clear()
				for fish in list
					gmap.addMarker
						title: "#{fish.name} x #{fish.count}"
						icon: icons[(_.min fish.count, 10) - 1]
						position:
							lat: fish.geoinfo.latitude
							lng: fish.geoinfo.longitude
			if others
				DistributionFactory.others fish_name, map_others
			else
				DistributionFactory.mine fish_name, map_mine

	$scope.$on '$ionicView.enter', (event, state) ->
		$log.debug "Enter DistributionMapCtrl: params=#{angular.toJson $stateParams}: event=#{angular.toJson event}"
		$ionicLoading.show()
		GMapFactory.onDiv $scope, 'distribution_map', (gmap) ->
			$scope.gmap = gmap
			$scope.map_distribution()
			$ionicLoading.hide()
