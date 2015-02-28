.directive 'fathensFitImg', ($log, $ionicScrollDelegate) ->
	getProp = (obj, [h, ...left]:list) ->
		next = obj[h]
		if next && left.length > 0
		then getProp(next, left)
		else next

	restrict: 'E'
	template: '<ion-scroll><div><img/></div></ion-scroll>'
	replace: true
	link: ($scope, $element, $attrs) !->
		div = $element.children!.children![0]
		img = $element.children!.children!.children!
		photo = $attrs['src']
		if photo && photo.length > 0
			chain = photo.split('.')
			$scope.$watch chain[0], !->
				photo-url = getProp $scope, chain
				if photo-url
					$log.debug "fathensFitImg: img=#{img}, photo=#{photo}, src=#{photo-url}"
					img.attr('src', photo-url)
					img.on 'load', !->
						rect =
							width: img[0].clientWidth
							height: img[0].clientHeight
						max = if document.documentElement.clientWidth < document.documentElement.clientHeight then rect.width else rect.height
						div.style.width = "#{_.min max, rect.width}px"
						div.style.height = "#{_.min max, rect.height}px"
						$log.debug "fathensFitImg: #{angular.toJson rect} ==> #{max}"
						# Scroll to center
						margin = (f) -> if max < f(rect) then (f(rect) - max)/2 else 0
						delegate-name = $attrs['delegateHandle']
						sc =
							left: margin (.width)
							top: margin (.height)
						$ionicScrollDelegate.$getByHandle(delegate-name).scrollTo sc.left, sc.top
						$log.debug "fathensFitImg: scroll=#{angular.toJson sc}, name=#{delegate-name}"

.directive 'textareaElastic', ($log) ->
	restrict: 'E'
	template: '<textarea ng-keypress="elasticTextarea()"></textarea>'
	replace: true
	scope: true
	controller: ($scope, $element, $attrs) ->
		$scope.elasticTextarea = !->
			area = $element[0]
			current = area.style.height
			next = "#{area.scroll-height + 20}px"
			if current != next
				$log.debug "Elastic #{area}: #{current} => #{next}"
				area.style.height = next

.directive 'fathensEditReport', ($log) ->
	restrict: 'E'
	templateUrl: 'page/report/editor-report.html'
	replace: true
	controller: ($scope, $element, $attrs, $timeout, $state, $ionicPopover, ConditionFactory, UnitFactory) ->
		$scope.popover = {}
		['spot-location', 'choose-tide', 'choose-weather'] |> _.each (name) !->
			$ionicPopover.fromTemplateUrl name,
				scope: $scope
			.then (popover) !->
				$scope.popover[_.camelize name] = popover
		$scope.popover-hide = !->
			for ,p of $scope.popover
				p?.hide!
		$scope.$on '$destroy', (event) !->
			$log.info "Leaving 'fathens-edit-report': #{event}"
			for ,p of $scope.popover
				p?.remove!

		$scope.tide-modified = false
		$scope.tide-modify = !->
			$log.debug "Condition tide modified by user: #{$scope.report.condition.tide}"
			$scope.tide-modified = true
		$scope.weather-modified = false
		$scope.weather-modify = !->
			$log.debug "Condition weather modified by user: #{$scope.report.condition.weather.name}"
			$scope.weather-modified = true
			$timeout !->
				$log.debug "Using weather icon by Name: #{$scope.report.condition.weather.name}"
				$scope.report?.condition?.weather.icon-url = $scope.weather-icon($scope.report.condition.weather.name)
			, 200

		$scope.$watch 'report.condition.tide', (new-value, old-value) !->
			$scope.popover.choose-tide.hide!
		$scope.$watch 'report.condition.weather.temperature.unit', (new-value, old-value) !->
			$scope.report?.condition?.weather.temperature = UnitFactory.temperature $scope.report.condition.weather.temperature
		$scope.$watch 'report.condition.weather.temperature.value', (new-value, old-value) !->
			$scope.report?.condition?.weather.temperature.value = Math.round(new-value * 10) / 10
		$scope.$watch 'report.condition.weather.name', (new-value, old-value) !->
			$scope.popover.choose-weather.hide!

		$scope.$watch 'report.dateAt', (new-value, old-value) !-> if old-value || !$scope.report?.condition
			change-condition(new-value, $scope.report?.location?.geoinfo)
		$scope.$watch 'report.location.geoinfo', (new-value, old-value) !-> if old-value || !$scope.report?.condition
			change-condition($scope.report?.dateAt, new-value)
		change-condition = (datetime, geoinfo) !-> if datetime && geoinfo
			$scope.report.condition = {} if !$scope.report.condition
			ConditionFactory.state datetime, geoinfo, (state) !->
				$log.debug "Conditions result: #{angular.toJson state}"
				$scope.report.condition.moon = state.moon
				if !$scope.tide-modified
					$scope.report.condition.tide = state.tide
				if state.weather
					if !$scope.weather-modified
						$scope.report.condition.weather = state.weather
					else
						$scope.report.condition.weather.temperature = state.weather.temperature

		$scope.moon-icon = -> ConditionFactory.moon-phases[$scope.report?.condition?.moon]
		$scope.tide-icon = -> $scope.tide-phases |> _.find (.name == $scope.report?.condition?.tide) |> (?.icon)
		$scope.weather-icon = (name) -> $scope.weather-states[name]

		$scope.tide-phases = ConditionFactory.tide-phases
		$scope.weather-states = ConditionFactory.weather-states

		$scope.spot-location-gmap =
			map: null
			marker: null
		$scope.showMap = ($event) !->
			gmap = $scope.spot-location-gmap
			geoinfo = $scope.report.location.geoinfo
			center = new google.maps.LatLng(geoinfo.latitude, geoinfo.longitude)
			$scope.popover.spot-location.show $event
			.then !->
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

				google.maps.event.addDomListener div, 'click', !->
					$scope.popover-hide!
					$scope.use-current!
					$state.go "view-on-map",
						edit: true

.directive 'fathensEditFishes', ($log) ->
	restrict: 'E'
	templateUrl: 'page/report/editor-fishes.html'
	replace: true
	scope: true
	controller: ($scope, $element, $attrs, $timeout, $ionicPopover, UnitFactory) ->
		$ionicPopover.fromTemplateUrl 'fish-edit',
			scope: $scope
		.then (popover) !->
			$scope.fish-edit = popover
		$scope.$on '$destroy', (event) !->
			$log.info "Leaving 'fathens-edit-fishes': #{event}"
			$scope.fish-edit?.remove!
		$scope.units = UnitFactory.units!
		$scope.user-units =
			length: 'cm'
			weight: 'kg'
		UnitFactory.load (units) !->
			$scope.user-units <<< units

		$scope.adding =
			name: null
		$scope.addFish = !->
			$log.debug "Adding fish: #{$scope.adding.name}"
			if !!$scope.adding.name
				$scope.report.fishes.push do
					name: $scope.adding.name
					count: 1
				$scope.adding.name = null
		$scope.editing = false
		$scope.editFish = (event, index) !->
			$scope.current = $scope.report.fishes[index]
			$scope.tmpFish = angular.copy $scope.current
			if !$scope.tmpFish.length?.value
				$scope.tmpFish.length =
					value: null
					unit: $scope.user-units.length
			if !$scope.tmpFish.weight?.value
				$scope.tmpFish.weight =
					value: null
					unit: $scope.user-units.weight
			$scope.editing = true
			$log.debug "Editing fish(#{index}): #{angular.toJson $scope.tmpFish}"
			$scope.fish-edit.show event
		$scope.$on 'popover.hidden', !-> if $scope.editing
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
	link: ($scope, $element, $attrs) !->
		$ionicLoading.show!
		gist-id = $attrs.id

		iframe = document.createElement 'iframe'
		iframe.setAttribute 'width', '100%'
		iframe.setAttribute 'height', '100%'
		iframe.setAttribute 'marginheight', 0
		iframe.setAttribute 'marginwidth', 0
		iframe.setAttribute 'frameborder', '0'
		iframe.id = "gist-#{gist-id}"
		$element[0].appendChild(iframe)

		doc = 
			if iframe.contentDocument
				iframe.contentDocument
			else
				if iframe.contentWindow?.document
					iframe.contentWindow.document 
				else
					iframe.document
		doc.open!
		doc.writeln """
			<html>
			<head>
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/gist-embed/2.1/gist-embed.min.js"></script>
			</head>
			<body>
				<code data-gist-id="#{gist-id}" data-gist-hide-footer="true" data-gist-show-loading="false"></code>
			</body>
			</html>
		"""
		doc.close!
		$ionicLoading.hide!
