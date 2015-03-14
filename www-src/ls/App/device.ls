.factory 'PhotoFactory', ($log) ->
	readExif = (photo, info-taker) !->
		try
			console.log "Reading Exif in #{photo}"
			reader = new ExifReader()
			reader.load photo
			toDate = (str) ->
				a = str.split(' ') |> _.map (.split ':') |> _.flatten |> _.map Number
				new Date(a[0], a[1] - 1, a[2], a[3], a[4], a[5])
			g =
				latitude: Number(reader.getTagDescription 'GPSLatitude')
				longitude: Number(reader.getTagDescription 'GPSLongitude')
			info-taker do
				timestamp: toDate(reader.getTagDescription 'DateTimeOriginal')
				geoinfo: if g.latitude && g.longitude then g else null
		catch
			console.log "Failed to read Exif: #{e.message}"
			info-taker null
	/*
		Select a photo from storage.
		onSuccess(exif-info, photo[blob])
		onFailure(error-message)
	*/
	select: (onSuccess, onFailure) !-> ionic.Platform.ready !->
		taker = (uri) !->
			try
				req = new XMLHttpRequest()
				req.open("GET", uri, true)
				req.responseType = "arraybuffer"
				req.onload = !->
					array = req.response
					readExif array, (info) !->
						onSuccess info, new Blob [array],
							type: 'image/jpeg'
				req.send!
			catch
				plugin.acra.handleSilentException "Failed to get photo(#{uri}): #{e.message}"
				onFailure "Failed to get photo"
		try
			navigator.camera.getPicture taker, onFailure,
				correctOrientation: true
				mediaType: navigator.camera.MediaType.PICTURE
				encodingType: Camera.EncodingType.JPEG
				sourceType: Camera.PictureSourceType.SAVEDPHOTOALBUM
				destinationType: Camera.DestinationType.NATIVE_URI
		catch
			plugin.acra.handleSilentException "Failed to select photo: #{e.message}"
			onFailure "Failed to select photo"

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

.factory 'GMapFactory', ($log, $ionicSideMenuDelegate, $timeout) ->
	store =
		gmap: null
	ionic.Platform.ready !->
		gmap = plugin.google.maps.Map.getMap do
			mapType: store.map-type = plugin.google.maps.MapTypeId.HYBRID
			controls:
				myLocationButton: true
				zoom: false
		gmap.on plugin.google.maps.event.MAP_READY, !->
			store.gmap = gmap
	menuShown = (isOpen) !->
		console.log "GMapFactory: side menu open: #{isOpen}"
		document.getElementsByClassName('menu-left')[0]?.style.display = if isOpen then 'block' else 'none'
		store.gmap.setClickable !isOpen
		$timeout store.gmap.refreshLayout, 200 if !isOpen
	marker = (clear-pre) -> (geoinfo, title, icon) !->
		store.gmap.clear! if clear-pre
		store.gmap.addMarker do
			position: new plugin.google.maps.LatLng(geoinfo.latitude, geoinfo.longitude)
			title: title
			icon: icon
	onReady = (proc) !->
		if store.gmap
		then proc!
		else plugin.google.maps.Map.getMap!.on plugin.google.maps.event.MAP_READY, proc
	clear = !->
		$log.info "Clear GMap"
		store.gmap.clear!
		store.gmap.off!
		store.gmap.setDiv null
		menuShown true

	add-marker: marker false
	put-marker: marker true
	clear: clear
	getMapTypes: ->
		"Roadmap": plugin.google.maps.MapTypeId.ROADMAP
		"Satellite": plugin.google.maps.MapTypeId.SATELLITE
		"Road + Satellite": plugin.google.maps.MapTypeId.HYBRID
		"Terrain": plugin.google.maps.MapTypeId.TERRAIN
	getMapType: -> store.map-type
	setMapType: (id) !-> onReady !->
		store.gmap.setMapTypeId store.map-type = id
	getGeoinfo: (onSuccess, onError) !-> onReady !->
		store.gmap.getMyLocation (location) !->
			$log.debug "Gotta GMap Location: #{angular.toJson location}"
			onSuccess do
				latitude: location.latLng.lat
				longitude: location.latLng.lng
		, (error) !->
			$log.error "GMap Location Error: #{angular.toJson error}"
			onError error if onError
	onDiv: (scope, name, success, center) !-> onReady !->
		clear!
		if center
			store.gmap.setZoom 10
			store.gmap.setCenter new plugin.google.maps.LatLng(center.latitude, center.longitude)
			marker(true) center
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
		div = document.getElementById name
		store.gmap.setDiv div
		store.gmap.setMapTypeId store.map-type
		store.gmap.setClickable true
		scope.$watch ->
			!!$ionicSideMenuDelegate.isOpenLeft!
		, menuShown
		success store.gmap if success
	onTap: (proc) !-> onReady !->
		$log.debug "GMap onTap is changed: #{proc}"
		store.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
			proc do
				latitude: latLng.lat
				longitude: latLng.lng
