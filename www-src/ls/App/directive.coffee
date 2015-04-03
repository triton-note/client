.directive 'fathensFitImg', ($log, $ionicScrollDelegate) ->
	getProp = (obj, [h, ...left]:list) ->
		next = obj[h]
		if next && left.length > 0
		then getProp(next, left)
		else next

	restrict: 'E'
	template: '<ion_scroll><div><img/></div></ion_scroll>'
	replace: true
	link: ($scope, $element, $attrs) ->
		div = $element.children().children()[0]
		img = $element.children().children().children()
		photo = $attrs['src']
		whole = ()!$attrs['whole']
		if photo && photo.length > 0
			chain = photo.split('.')
			$scope.$watch chain[0], ->
				photo_url = getProp $scope, chain
				if photo_url
					$log.debug "fathensFitImg: img=#{img}, photo=#{photo}, src=#{photo_url}"
					img.attr('src', photo_url)
					img.on 'load', ->
						rect =
							width: img[0].clientWidth
							height: img[0].clientHeight
						# Fit width
						max = if document.documentElement.clientWidth < document.documentElement.clientHeight then rect.width else rect.height
						div.style.width = "#{_.min max, rect.width}px"
						div.style.height = "#{_.min max, rect.height}px"
						$log.debug "fathensFitImg: #{angular.toJson rect} ==> #{max}"
						# Scroll to center
						delegate = $ionicScrollDelegate.$getByHandle $attrs['delegateHandle']
						if delegate
							margin = (f) -> if max < f(rect) then (f(rect) - max)/2 else 0
							sc =
								left: margin (.width)
								top: margin (.height)
							delegate.scrollTo sc.left, sc.top
							$log.debug "fathensFitImg: scroll=#{angular.toJson sc}"
							min_zoom = _.min 1, if document.documentElement.clientWidth < document.documentElement.clientHeight
								then rect.width / rect.height
								else rect.height / rect.width
							if whole && min_zoom < 1
								delegate.zoomTo min_zoom, true

.directive 'fathensEditReport', ($log) ->
	restrict: 'E'
	templateUrl: 'page/report/editor_report.html'
	replace: true
	controller: ($scope, $element, $attrs, $timeout, $state, $ionicPopover, ConditionFactory, UnitFactory) ->
		$scope.popover = {}
		['spot_location', 'choose_tide', 'choose_weather'] |> _.each (name) ->
			$ionicPopover.fromTemplateUrl name,
				scope: $scope
			.then (popover) ->
				$scope.popover[_.camelize name] = popover
		$scope.popover_hide = ->
			for ,p of $scope.popover
				p?.hide()
		$scope.$on '$destroy', (event) ->
			$log.info "Leaving 'fathens_edit_report': #{event}"
			for ,p of $scope.popover
				p?.remove()

		$scope.tide_modified = false
		$scope.tide_modify = ->
			$log.debug "Condition tide modified by user: #{$scope.report.condition.tide}"
			$scope.tide_modified = true
		$scope.weather_modified = false
		$scope.weather_modify = ->
			$log.debug "Condition weather modified by user: #{$scope.report.condition.weather.name}"
			$scope.weather_modified = true
			$timeout ->
				$log.debug "Using weather icon by Name: #{$scope.report.condition.weather.name}"
				$scope.report?.condition?.weather.icon_url = $scope.weather_icon($scope.report.condition.weather.name)
			, 200

		$scope.$watch 'report.condition.tide', (new_value, old_value) ->
			$scope.popover.choose_tide.hide()
		$scope.$watch 'report.condition.weather.temperature.unit', (new_value, old_value) ->
			$scope.report?.condition?.weather.temperature = UnitFactory.temperature $scope.report.condition.weather.temperature
		$scope.$watch 'report.condition.weather.temperature.value', (new_value, old_value) ->
			$scope.report?.condition?.weather.temperature.value = Math.round(new_value * 10) / 10
		$scope.$watch 'report.condition.weather.name', (new_value, old_value) ->
			$scope.popover.choose_weather.hide()

		$scope.$watch 'report.dateAt', (new_value, old_value) -> if old_value || !$scope.report?.condition
			change_condition(new_value, $scope.report?.location?.geoinfo)
		$scope.$watch 'report.location.geoinfo', (new_value, old_value) -> if old_value || !$scope.report?.condition
			change_condition($scope.report?.dateAt, new_value)
		change_condition = (datetime, geoinfo) -> if datetime && geoinfo
			$scope.report.condition = {} if !$scope.report.condition
			ConditionFactory.state datetime, geoinfo, (state) ->
				$log.debug "Conditions result: #{angular.toJson state}"
				$scope.report.condition.moon = state.moon
				if !$scope.tide_modified
					$scope.report.condition.tide = state.tide
				if state.weather
					if !$scope.weather_modified
						$scope.report.condition.weather = state.weather
					else
						$scope.report.condition.weather.temperature = state.weather.temperature

		$scope.moon_icon = -> ConditionFactory.moon_phases[$scope.report?.condition?.moon]
		$scope.tide_icon = -> $scope.tide_phases |> _.find (.name == $scope.report?.condition?.tide) |> (?.icon)
		$scope.weather_icon = (name) -> $scope.weather_states[name]

		$scope.tide_phases = ConditionFactory.tide_phases
		$scope.weather_states = ConditionFactory.weather_states

		$scope.spot_location_gmap =
			map: null
			marker: null
		$scope.showMap = ($event) ->
			gmap = $scope.spot_location_gmap
			geoinfo = $scope.report.location.geoinfo
			center = new google.maps.LatLng(geoinfo.latitude, geoinfo.longitude)
			$scope.popover.spot_location.show $event
			.then ->
				div = document.getElementById "gmap"
				unless gmap.map
					gmap.map = new google.maps.Map div,
						mapTypeId: google.maps.MapTypeId.HYBRID
						disableDefaultUI: true
				gmap.map.setCenter center
				gmap.map.setZoom 8

				gmap.marker?.setMap null
				gmap.marker = new google.maps.Marker do
					title: $scope.report.location.name
					map: gmap.map
					position: center
					animation: google.maps.Animation.DROP

				google.maps.event.addDomListener div, 'click', ->
					$scope.popover_hide()
					$scope.use_current()
					$state.go "view_on_map",
						edit: true

.directive 'fathensEditFishes', ($log) ->
	restrict: 'E'
	templateUrl: 'page/report/editor_fishes.html'
	replace: true
	scope: true
	controller: ($scope, $element, $attrs, $timeout, $ionicPopover, UnitFactory) ->
		$ionicPopover.fromTemplateUrl 'fish_edit',
			scope: $scope
		.then (popover) ->
			$scope.fish_edit = popover
		$scope.$on '$destroy', (event) ->
			$log.info "Leaving 'fathens_edit_fishes': #{event}"
			$scope.fish_edit?.remove()
		$scope.units = UnitFactory.units()
		$scope.user_units =
			length: 'cm'
			weight: 'kg'
		UnitFactory.load (units) ->
			$scope.user_units <<< units

		$scope.adding =
			name: null
		$scope.addFish = ->
			$log.debug "Adding fish: #{$scope.adding.name}"
			if ()!$scope.adding.name
				$scope.report.fishes.push do
					name: $scope.adding.name
					count: 1
				$scope.adding.name = null
		$scope.editing = false
		$scope.editFish = (event, index) ->
			$scope.current = $scope.report.fishes[index]
			$scope.tmpFish = angular.copy $scope.current
			if !$scope.tmpFish.length?.value
				$scope.tmpFish.length =
					value: null
					unit: $scope.user_units.length
			if !$scope.tmpFish.weight?.value
				$scope.tmpFish.weight =
					value: null
					unit: $scope.user_units.weight
			$scope.editing = true
			$log.debug "Editing fish(#{index}): #{angular.toJson $scope.tmpFish}"
			$scope.fish_edit.show event
		$scope.$on 'popover.hidden', -> if $scope.editing
			$scope.editing = false
			$log.debug "Hide popover"
			if $scope.tmpFish?.name && $scope.tmpFish?.count
				if !$scope.tmpFish.length?.value
					$scope.tmpFish.length = undefined
				if !$scope.tmpFish.weight?.value
					$scope.tmpFish.weight = undefined
				$log.debug "Overrinding current fish"
				$scope.current <<< $scope.tmpFish

.directive 'gist', ($log, $ionicLoading) ->
	restrict: 'E',
	replace: true,
	template: '<div></div>',
	link: ($scope, $element, $attrs) ->
		$ionicLoading.show()
		gist_id = $attrs.id

		iframe = document.createElement 'iframe'
		iframe.setAttribute 'width', '100%'
		iframe.setAttribute 'height', '100%'
		iframe.setAttribute 'marginheight', 0
		iframe.setAttribute 'marginwidth', 0
		iframe.setAttribute 'frameborder', '0'
		iframe.id = "gist-#{gist_id}"
		$element[0].appendChild(iframe)

		doc = 
			if iframe.contentDocument
				iframe.contentDocument
			else
				if iframe.contentWindow?.document
					iframe.contentWindow.document 
				else
					iframe.document
		doc.open()
		doc.write """
			<html>
			<head>
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/gist_embed/2.1/gist_embed.min.js"></script>
			</head>
			<body>
				<code data_gist_id="#{gist_id}" data_gist_hide_footer="true" data_gist_show_loading="false"></code>
			</body>
			</html>
		"""
		doc.close()
		$ionicLoading.hide()
