.directive 'fathensGoogleMaps', ($log) ->
	raw = (jqe) ->
		e = jqe[0]
		maxH = document.documentElement.clientHeight
		eTop = e.getBoundingClientRect!.top
		h= (maxH - eTop)
		e.style.height = "#{h}px"
		$log.debug "Calculating: doc.h=#{maxH}, e.top=#{eTop}  ==> #{h}"
		e

	restrict: 'E'
	template: '<div></div>'
	replace: true
	scope: false
	controller:	($scope, $element, $attrs) !->
		ionic.Platform.ready !->
			$log.debug "Linking directie fathens-google-maps by controller"
			gmap = plugin.google.maps.Map.getMap do
				mapType: plugin.google.maps.MapTypeId.HYBRID
				controls:
					myLocationButton: true
					zoom: false
			gmap.on plugin.google.maps.event.MAP_READY, (gmap) !->
				visible = (value) !->
					$log.debug "gmap-visible is changed: #{value}"
					v = value == true
					gmap.setDiv(if v then raw($element) else null)
					gmap.setVisible v
					map-type $scope.gmap-type
					map-center $scope.gmap-center
					if $scope[$attrs.fathens-gmap ? 'gmap'] then
						that.obj = gmap
				map-center = (value) !->
					if value then
						gmap.setCenter do
							lat: value.latitude
							lng: value.longitude
				map-type = (value) !->
					v = switch value
					| 'ROADMAP'   => plugin.google.maps.MapTypeId.ROADMAP
					| 'SATELLITE' => plugin.google.maps.MapTypeId.SATELLITE
					| 'HYBRID'    => plugin.google.maps.MapTypeId.HYBRID
					| 'TERRAIN'   => plugin.google.maps.MapTypeId.TERRAIN
					| _           => plugin.google.maps.MapTypeId.HYBRID
					$log.debug "Set Map type: #{v}"
					gmap.setMapTypeId v
				$scope.$watch 'gmapVisible', visible
				$scope.$watch 'gmapType', map-type
				$scope.$watch 'gmapCenter', map-center
				$log.debug "GMap is shown: #{gmap}"
				gmap.on plugin.google.maps.event.MAP_CLOSE, (e) !->
					$log.debug "Close map in element"
					visible false
