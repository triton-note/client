.controller 'BaseCtrl', ($log, $scope, $ionicModal) !->
	$ionicModal.fromTemplateUrl 'template/add-record.html'
		, (modal) !-> $scope.modalAddRecord = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.addRecord = !-> $scope.modalAddRecord.show!

	$scope.openMap = !-> alert "Open Map"

.controller 'TopCtrl', ($log, $scope, RecordFactory) !->
	$scope.records = RecordFactory.load!
	$scope.detail = (index) !->
		alert "Click #index => #{$scope.records[index].image}"

.controller 'AddRecordCtrl', ($log, $scope, RecordFactory) !->
	$scope.photo = null
	$scope.dateAt = new Date!
	$scope.location = "Here"

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
