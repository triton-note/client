.factory 'PhotoFactory', ($log) ->
	/*
		Select a photo from storage.
		onSuccess(image-uri)
		onFailure(error-message)
	*/
	select: (onSuccess, onFailure) !->
		isAndroid = device.platform == 'Android'
		$log.info "Selecting a photo: android=#{isAndroid}"
		taker = (ret) !->
			$log.info "Photo is selected"
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
	store =
		gmap: null
	create-map = !->
		store.gmap = plugin.google.maps.Map.getMap do
			mapType: plugin.google.maps.MapTypeId.HYBRID
			controls:
				myLocationButton: true
				zoom: false
	marker = (clear-pre) -> (geoinfo, title, icon) !->
		store.gmap.clear! if clear-pre
		store.gmap.addMarker do
			position: new plugin.google.maps.LatLng(geoinfo.latitude, geoinfo.longitude)
			title: title
			icon: icon

	fill-height = (e) ->
		maxH = document.documentElement.clientHeight
		eTop = e.getBoundingClientRect!.top
		h= (maxH - eTop)
		e.style.height = "#{h}px"
		$log.debug "Calculating: doc.h=#{maxH}, e.top=#{eTop}  ==> #{h}"
		e

	onDiv: (name, success, center) ->
		@clear! if store.gmap
		create-map!
		if center
			store.gmap.setZoom 10
			store.gmap.setCenter new plugin.google.maps.LatLng(center.latitude, center.longitude)
			@put-marker center
		else
			store.gmap.getCameraPosition (camera) !->
				$log.debug "Camera Position: #{angular.toJson camera}"
				if camera.zoom == 2 && camera.target.lat == 0 && camera.target.lng == 0
					store.gmap.setZoom 10
					navigator.geolocation.getCurrentPosition (pos) !->
						$log.debug "Gotta geolocation: #{angular.toJson pos}"
						store.gmap.setCenter new plugin.google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
					, (error) !->
						$log.error "Geolocation Error: #{angular.toJson error}"
		document.getElementById name |> fill-height |> store.gmap.setDiv
		success store.gmap if success
	add-marker: marker false
	put-marker: marker true
	clear: !->
		store.gmap.clear!
		store.gmap.off!
		store.gmap.setDiv null
	onTap: (proc) !->
		$log.debug "GMap onTap is changed: #{proc}"
		store.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
			proc do
				latitude: latLng.lat
				longitude: latLng.lng
