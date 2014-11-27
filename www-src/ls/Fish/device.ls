.factory 'PhotoFactory', ->
	/*
		Select a photo from storage.
		onSuccess(image-uri)
		onFailure(error-message)
	*/
	select: (onSuccess, onFailure) !->
		isAndroid = device.platform == 'Android'
		taker = (ret) !->
			onSuccess (if isAndroid
			then "data:image/jpeg;base64,#{ret}"
			else ret)
		navigator.camera.getPicture taker, onFailure,
			correctOrientation: true
			encodingType: Camera.EncodingType.JPEG
			sourceType: Camera.PictureSourceType.PHOTOLIBRARY
			destinationType: if isAndroid
				then Camera.DestinationType.DATA_URL
				else Camera.DestinationType.FILE_URI

.factory 'LocalStorageFactory', ($log) ->
	names = []
	make = (name, isJson = false) ->
		loader = switch isJson
		| true => (v) -> angular.fromJson v
		| _    => (v) -> v
		saver = switch isJson
		| true => (v) -> angular.toJson v
		| _    => (v) -> v

		names.push name

		load: -> 
			v = window.localStorage[name] ? null
			$log.debug "localStorage['#{name}'] => #{v}"
			if v then loader(v)	else null
		save: (v) ->
			value = if v then saver(v) else null
			$log.debug "localStorage['#{name}'] <= #{value}"
			window.localStorage[name] = value
			v
		remove: !->
			window.localStorage.removeItem name

	clear-all: !-> for name in names
		window.localStorage.removeItem name
	/*
	Express the account of login
		id: String
		name: String
	*/
	account: make 'account', true
	/*
	Boolean value for acceptance of 'Terms Of Use and Disclaimer'
	*/
	acceptance: make 'Acceptance'

.factory 'GMapFactory', ($log) ->
	gmap = null
	add-marker = (latLng, success) !->
		gmap.addMarker {
			position: latLng
		}, (marker) !->
			m =
				marker: marker
				geoinfo:
					latitude: latLng.lat
					longitude: latLng.lng
			success m if success

	fill-height = (e) ->
		maxH = document.documentElement.clientHeight
		eTop = e.getBoundingClientRect!.top
		h= (maxH - eTop)
		e.style.height = "#{h}px"
		$log.debug "Calculating: doc.h=#{maxH}, e.top=#{eTop}  ==> #{h}"
		e

	onDiv: (name, success, center) ->
		ionic.Platform.ready !->
			gmap = plugin.google.maps.Map.getMap do
				mapType: plugin.google.maps.MapTypeId.HYBRID
				controls:
					myLocationButton: true
					zoom: false
			if center
				gmap.setZoom 10
				pos = new plugin.google.maps.LatLng(center.latitude, center.longitude)
				gmap.setCenter pos
				add-marker pos
			else
				gmap.getCameraPosition (camera) !->
					$log.debug "Camera Position: #{angular.toJson camera}"
					if camera.zoom == 2 && camera.target.lat == 0 && camera.target.lng == 0
						gmap.setZoom 10
						navigator.geolocation.getCurrentPosition (pos) !->
							$log.debug "Gotta geolocation: #{angular.toJson pos}"
							gmap.setCenter new plugin.google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
						, (error) !->
							$log.error "Geolocation Error: #{angular.toJson error}"
			document.getElementById name |> fill-height |> gmap.setDiv
			success gmap if success
	clear: !->
		gmap.clear!
		gmap.off!
		gmap.setDiv null
	onTap: (proc) !->
		$log.debug "GMap onTap is changed: #{proc}"
		if proc	then
			gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
				$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
				add-marker latLng, proc
