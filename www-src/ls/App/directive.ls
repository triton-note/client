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
			next = area.scroll-height + "px"
			if current != next
				$log.debug "Elastic #{area}: #{current} => #{next}"
				area.style.height = next
