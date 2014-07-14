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
					if $scope[$attrs.fathens-gmap ? 'gmap'] then
						that.obj = gmap
				$scope.$watch 'gmapVisible', visible
				$log.debug "GMap is shown: #{gmap}"
				gmap.on plugin.google.maps.event.MAP_CLOSE, (e) !->
					$log.debug "Close map in element"
					visible false
