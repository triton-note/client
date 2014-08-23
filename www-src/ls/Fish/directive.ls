.directive 'fathensGoogleMaps', ($log) ->
	arrange-heiht = (jqe) ->
		e = jqe[0]
		maxH = document.documentElement.clientHeight
		eTop = e.getBoundingClientRect!.top
		h= (maxH - eTop)
		e.style.height = "#{h}px"
		$log.debug "Calculating: doc.h=#{maxH}, e.top=#{eTop}  ==> #{h}"

	restrict: 'E'
	template: '<div></div>'
	replace: true
	scope: false
	controller:	($scope, $element, $attrs) !->
		gmap-setter = $attrs.fathens-gmap-setter ? 'setGmap'
		gmap-visible = $attrs.fathens-gmap-visible ? 'gmapVisible'
		gmap-type = $attrs.fathens-gmap-type ? 'gmapType'
		gmap-center = $attrs.fathens-gmap-center ? 'gmapCenter'
		gmap-onTap = $attrs.fathens-gmap-onTap ? 'gmapOnTap'
		gmap-markers = $attrs.fathens-gmap-markers ? 'gmapMarkers'

		ionic.Platform.ready !->
			$log.debug "Linking directie fathens-google-maps by controller"
			gmap = plugin.google.maps.Map.getMap do
				mapType: plugin.google.maps.MapTypeId.HYBRID
				controls:
					myLocationButton: true
					zoom: false
			gmap.on plugin.google.maps.event.MAP_READY, (gmap) !->
				arrange-heiht $element
				default-view = !->
					gmap.setZoom 10
					navigator.geolocation.getCurrentPosition do
						(pos) !->
							$log.debug "Gotta geolocation: #{angular.toJson pos}"
							gmap.setCenter new plugin.google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
						, (error) !->
							$log.error "Geolocation Error: #{angular.toJson error}"
				visible = (value) !->
					gmap.clear!
					gmap.off!
					v = value == true
					if v
					then
						$log.debug "gmap-visible(#{gmap-visible}) is changed: #{value}"
						gmap.setDiv $element[0]
						gmap.getCameraPosition (camera) !->
							if camera.zoom == 2 && camera.target.lat == 0 && camera.target.lng == 0
								default-view!
						map-type $scope[gmap-type]
						map-center $scope[gmap-center]
						map-onTap $scope[gmap-onTap]
						if $scope[gmap-setter] then
							that gmap
					else
						gmap.setDiv null
					gmap.setVisible v
				map-center = (value) !->
					$log.debug "gmap-center(#{gmap-center}) is changed: #{value}"
					if value then
						center =
							lat: value.latitude
							lng: value.longitude
						gmap.setCenter center
						gmap.addMarker {
							position: center
						}, (m) !->
							$scope[gmap-markers]?.push m
				map-onTap = (proc) !->
					$log.debug "gmap-onTap(#{gmap-onTap}) is changed: #{proc}"
					if proc	then
						gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
							$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
							gmap.addMarker {
								position: latLng
							}, (m) !->
								$scope[gmap-markers]?.push m
								proc m,
									latitude: latLng.lat
									longitude: latLng.lng
				map-type = (value) !->
					$log.debug "gmap-type(#{gmap-type}) is changed: #{value}" if value
					v = switch value
					| 'ROADMAP'   => plugin.google.maps.MapTypeId.ROADMAP
					| 'SATELLITE' => plugin.google.maps.MapTypeId.SATELLITE
					| 'HYBRID'    => plugin.google.maps.MapTypeId.HYBRID
					| 'TERRAIN'   => plugin.google.maps.MapTypeId.TERRAIN
					| _           => plugin.google.maps.MapTypeId.HYBRID
					$log.debug "Set Map type: #{v}" if value
					gmap.setMapTypeId v
				$scope.$watch gmap-visible, visible
				$scope.$watch gmap-type, map-type
				$log.debug "GMap is shown: #{gmap}"
				gmap.on plugin.google.maps.event.MAP_CLOSE, (e) !->
					$log.debug "Close map in element:#{$element}"
					visible false
