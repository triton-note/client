.controller 'BaseCtrl', ($log, $scope, PhotoFactory) !->
	$scope.openMap = !-> alert "Open Map"

.controller 'TopCtrl', ($log, $scope, RecordFactory) !->
	$scope.records = RecordFactory.load!
	$scope.detail = (index) !->
		alert "Click #index => #{$scope.records[index].image}"

.controller 'AddRecordCtrl', ($log, $scope, $ionicModal, $ionicPopup, PhotoFactory, RecordFactory) !->
	newRecord = (uri) ->
		photo: uri
		dateAt: new Date!
		location:
			name: "Here"
			latLng: null
		fishes: []
		comment: ""

	$ionicModal.fromTemplateUrl 'template/add-record.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.open = !->
		$log.info "Opening modal..."
		PhotoFactory.select (uri) !->
			$scope.$apply $scope.record = newRecord uri
			$scope.modal.show!
		, (msg) !->
			$ionicPopup.alert {
				title: "No photo selected"
				subTitle: "Need a photo to record"
			}

	$scope.setLatLng = (latLng) !-> $scope.record.location.latLng = latLng

	$scope.cancel = !-> $scope.modal.hide!
	$scope.submit = (record) !->
		RecordFactory.add record
		$scope.modal.hide!

.controller 'GMapCtrl', ($log, $scope) !->
	$scope.markar = null

	create-map = (setter) !->
		$scope.gmap = plugin.google.maps.Map.getMap {
			'mapType': plugin.google.maps.MapTypeId.HYBRID
			'controls':
				'myLocationButton': true
				'zoom': true
		}
		$scope.gmap.on plugin.google.maps.event.MAP_READY, (gmap) !-> gmap.showDialog!
		$scope.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			setter latLng
			$scope.markar?.remove!
			$scope.gmap.addMarker {
				'position': latLng
			}, (marker) !->
				$scope.$apply $scope.markar = marker

	$scope.showMap = (setter) !->
		if $scope.gmap
			$scope.gmap.showDialog!
		else
			create-map setter
