.controller 'BaseCtrl', ($log, $scope, $ionicModal, $ionicPopup, PhotoFactory) !->
	$ionicModal.fromTemplateUrl 'template/add-record.html'
		, (modal) !-> $scope.modalAddRecord = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.addRecord = !->
		PhotoFactory.select (uri) !->
			$scope.$apply $scope.photo = uri
			$scope.modalAddRecord.show!
		, (msg) !->
			$ionicPopup.alert {
				title: "No photo selected"
				subTitle: "Need a photo to record"
			}

	$scope.openMap = !-> alert "Open Map"

.controller 'TopCtrl', ($log, $scope, RecordFactory) !->
	$scope.records = RecordFactory.load!
	$scope.detail = (index) !->
		alert "Click #index => #{$scope.records[index].image}"

.controller 'AddRecordCtrl', ($log, $scope, RecordFactory) !->
	$scope.dateAt = new Date!
	$scope.location = "Here"
	$scope.fishes = []

	$scope.cancel = !-> $scope.modalAddRecord.hide!
	$scope.submit = !-> $scope.modalAddRecord.hide!

.controller 'GMapCtrl', ($log, $scope) !->
	$scope.position = null
	$scope.markar = null

	create-map = !->
		$scope.gmap = plugin.google.maps.Map.getMap {
			'mapType': plugin.google.maps.MapTypeId.HYBRID
			'controls':
				'myLocationButton': true
				'zoom': true
		}
		$scope.gmap.on plugin.google.maps.event.MAP_READY, (gmap) !-> gmap.showDialog!
		$scope.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			$scope.position = latLng
			$scope.markar?.remove!
			$scope.gmap.addMarker {
				'position': latLng
			}, (marker) !->
				$scope.$apply $scope.markar = marker

	$scope.showMap = !->
		if $scope.gmap
			$scope.gmap.showDialog!
		else
			create-map!
