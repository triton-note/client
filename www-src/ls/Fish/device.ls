.factory 'PhotoFactory', ($log) ->
	/*
		Select a photo from storage.
		onSuccess(photo[blob or uri])
		onFailure(error-message)
	*/
	select: (onSuccess, onFailure) !->
		isAndroid = ionic.Platform.isAndroid!
		taker = (ret) !->
			toBlob = (src) ->
				bytes = atob src
				array = new Uint8Array(bytes.length)
				for i from 0 to bytes.length - 1
					array[i] = bytes.charCodeAt(i)
				new Blob [array],
					type: 'image/jpeg'
			if isAndroid
			then onSuccess toBlob(ret)
			else onSuccess ret
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
	ionic.Platform.ready !->
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

	add-marker: marker false
	put-marker: marker true
	clear: !->
		$log.info "Clear GMap"
		store.gmap.clear!
		store.gmap.off!
		store.gmap.setDiv null
	getGeoinfo: (onSuccess, onError) !->
		store.gmap.getMyLocation (location) !->
			$log.debug "Gotta GMap Location: #{angular.toJson location}"
			onSuccess do
				latitude: location.latLng.lat
				longitude: location.latLng.lng
		, (error) !->
			$log.error "GMap Location Error: #{angular.toJson error}"
			onError error if onError
	onDiv: (name, success, center) ->
		@clear! if store.gmap
		if center
			store.gmap.setZoom 10
			store.gmap.setCenter new plugin.google.maps.LatLng(center.latitude, center.longitude)
			@put-marker center
		else
			store.gmap.getCameraPosition (camera) !->
				$log.debug "Camera Position: #{angular.toJson camera}"
				if camera.zoom == 2 && camera.target.lat == 0 && camera.target.lng == 0
					store.gmap.setZoom 10
					store.gmap.getMyLocation (location) !->
						$log.debug "Gotta GMap Location: #{angular.toJson location}"
						store.gmap.setCenter location.latLng
					, (error) !->
						$log.error "GMap Location Error: #{angular.toJson error}"
		document.getElementById name |> store.gmap.setDiv
		success store.gmap if success
	onTap: (proc) !->
		$log.debug "GMap onTap is changed: #{proc}"
		store.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
			proc do
				latitude: latLng.lat
				longitude: latLng.lng
