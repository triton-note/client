.directive 'fathensGoogleMaps', ($log) ->
	arrange-heiht = (jqe) ->
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
		gmap-setter = $attrs.fathens-gmap-setter ? 'setGmap'
		gmap-visible = $attrs.fathens-gmap-visible ? 'gmapVisible'
		gmap-type = $attrs.fathens-gmap-type ? 'gmapType'
		gmap-center = $attrs.fathens-gmap-center ? 'gmapCenter'
		gmap-onTap = $attrs.fathens-gmap-onTap ? 'gmapOnTap'
		gmap-markers = $attrs.fathens-gmap-markers ? 'gmapMarkers'

		ionic.Platform.ready !->
			$log.debug "Linking directive fathens-google-maps by controller"
			gmap = plugin.google.maps.Map.getMap do
				mapType: plugin.google.maps.MapTypeId.HYBRID
				controls:
					myLocationButton: true
					zoom: false
			gmap.on plugin.google.maps.event.MAP_READY, (gmap) !->
				visible = (value) !->
					$log.debug "gmap-visible(#{gmap-visible}) is changed: #{value}"
					if value != true then
						gmap.clear!
						gmap.off!
						gmap.setDiv null
					else
						setup = !->
							map-type $scope[gmap-type]
							map-center $scope[gmap-center]
							map-onTap $scope[gmap-onTap]
							gmap.setDiv arrange-heiht($element)
							if $scope[gmap-setter] then
								that gmap
						default-view = !->
							gmap.setZoom 10
							navigator.geolocation.getCurrentPosition do
								(pos) !->
									$log.debug "Gotta geolocation: #{angular.toJson pos}"
									gmap.setCenter new plugin.google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
									setup!
								, (error) !->
									$log.error "Geolocation Error: #{angular.toJson error}"
									setup!
						gmap.getCameraPosition (camera) !->
							if camera.zoom == 2 && camera.target.lat == 0 && camera.target.lng == 0
							then
								default-view!
							else
								setup!
				add-marker = (latLng, success) !->
					gmap.addMarker {
						position: latLng
					}, (marker) !->
						m =
							marker: marker
							geoinfo:
								latitude: latLng.lat
								longitude: latLng.lng
						$scope[gmap-markers]?.push m
						success m if success
				map-center = (value) !->
					$log.debug "gmap-center(#{gmap-center}) is changed: #{value}"
					if value then
						center =
							lat: value.latitude
							lng: value.longitude
						gmap.setCenter center
						add-marker center
				map-onTap = (proc) !->
					$log.debug "gmap-onTap(#{gmap-onTap}) is changed: #{proc}"
					if proc	then
						gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
							$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
							add-marker latLng, proc
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
				$log.debug "GMap is ready: #{gmap}"
