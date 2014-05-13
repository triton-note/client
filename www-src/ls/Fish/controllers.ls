.controller 'BaseCtrl', ($log, $scope) !->
	$scope.current = null
	$scope.refresh = !->
		if (!$scope.gmap)
			$scope.gmap = plugin.google.maps.Map.getMap document.getElementById('google-map'),
				'mapType': plugin.google.maps.MapTypeId.HYBRID
				'controls':
					'myLocationButton': true
					'zoom': true
			$scope.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
				$scope.current?.remove!
				$scope.gmap.addMarker {
					'position': latLng
				}, (marker) !->
					$scope.current = marker
