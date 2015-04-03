angular.module('triton_note.device', [])
.factory 'PhotoFactory', ($log, $timeout) ->
	readExif = (photo, info_taker) ->
		try
			console.log "Reading Exif in #{photo}"
			reader = new ExifReader()
			reader.load photo
			toDate = (str) -> if !str then null else
				a = str.split(/[ :]/).map Number
				new Date(a[0], a[1] - 1, a[2], a[3], a[4], a[5])
			g =
				latitude: Number(reader.getTagDescription 'GPSLatitude')
				longitude: Number(reader.getTagDescription 'GPSLongitude')
			info_taker
				timestamp: toDate(reader.getTagDescription 'DateTimeOriginal')
				geoinfo: if g.latitude and g.longitude then g else null
		catch
			console.log "Failed to read Exif: #{e.message}"
			info_taker null
	###
		Select a photo from storage.
		photo_taker(photo[blob])
		info_taker(exif_info)
		onFailure(error_message)
	###
	select: (photo_taker, info_taker, onFailure) -> ionic.Platform.ready ->
		taker = (uri) ->
			console.log "Loading photo: #{uri}"
			resolveLocalFileSystemURL uri
			, (entry) ->
				entry.file (file) ->
					try
						reader = new FileReader
						reader.onloadend = (evt) ->
							try
								array = evt.target.result
								console.log "Read photo success: #{array}"
								$timeout ->
									readExif array, info_taker
								, 100
								photo_taker new Blob [array],
									type: 'image/jpeg'
							catch
								plugin.acra.handleSilentException "Failed to read photo(#{uri}): #{e.message}: #{e.stack}"
								onFailure "Failed to get photo"
						reader.onerror = (evt) ->
							onFailure "Failed to read photo file"
						reader.readAsArrayBuffer file
					catch
						plugin.acra.handleSilentException "Failed to get photo(#{uri}): #{e.message}: #{e.stack}"
						onFailure "Failed to get photo"
				, (error) ->
					console.log "Failed to get photo file: #{uri}"
					onFailure "Failed to get photo file"
			, (error) ->
				console.log "Failed to parse photo uri: #{uri}"
				onFailure "Failed to parse photo uri"
		try
			navigator.camera.getPicture taker, onFailure,
				correctOrientation: true
				mediaType: navigator.camera.MediaType.PICTURE
				encodingType: Camera.EncodingType.JPEG
				sourceType: Camera.PictureSourceType.PHOTOLIBRARY
				destinationType: Camera.DestinationType.FILE_URI
		catch
			plugin.acra.handleSilentException "Failed to select photo: #{e.message}: #{e.stack}"
			onFailure "Failed to select photo"

.factory 'LocalStorageFactory', ($log) ->
	names = []
	make = (name, isJson = false) ->
		loader = (v) -> if isJson then angular.fromJson(v) else v
		saver = (v) -> if isJson then angular.toJson(v) else v

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
		remove: ->
			window.localStorage.removeItem name

	clear_all: -> for name in names
		window.localStorage.removeItem name
	###
	Express the account of login
		id: String
		name: String
	###
	account: make 'account', true
	###
	Boolean value for acceptance of 'Terms Of Use and Disclaimer'
	###
	acceptance: make 'Acceptance'

.factory 'GMapFactory', ($log, $ionicSideMenuDelegate, $timeout) ->
	store =
		gmap: null
	ionic.Platform.ready ->
		gmap = plugin.google.maps.Map.getMap
			mapType: store.map_type = plugin.google.maps.MapTypeId.HYBRID
			controls:
				myLocationButton: true
				zoom: false
		gmap.on plugin.google.maps.event.MAP_READY, ->
			store.gmap = gmap
	menuShown = (isOpen) ->
		console.log "GMapFactory: side menu open: #{isOpen}"
		document.getElementsByClassName('menu_left')[0]?.style.display = if isOpen then 'block' else 'none'
		store.gmap.setClickable !isOpen
		$timeout store.gmap.refreshLayout, 200 if !isOpen
	marker = (clear_pre) -> (geoinfo, title, icon) ->
		store.gmap.clear() if clear_pre
		store.gmap.addMarker
			position: new plugin.google.maps.LatLng(geoinfo.latitude, geoinfo.longitude)
			title: title
			icon: icon
	onReady = (proc) ->
		if store.gmap
		  proc()
		else
			plugin.google.maps.Map.getMap().on plugin.google.maps.event.MAP_READY, proc
	clear = ->
		$log.info "Clear GMap"
		store.gmap.clear()
		store.gmap.off()
		store.gmap.setDiv null
		menuShown true

	add_marker: marker false
	put_marker: marker true
	clear: clear
	getMapTypes: ->
		"Roadmap": plugin.google.maps.MapTypeId.ROADMAP
		"Satellite": plugin.google.maps.MapTypeId.SATELLITE
		"Road + Satellite": plugin.google.maps.MapTypeId.HYBRID
		"Terrain": plugin.google.maps.MapTypeId.TERRAIN
	getMapType: -> store.map_type
	setMapType: (id) -> onReady ->
		store.gmap.setMapTypeId store.map_type = id
	getGeoinfo: (onSuccess, onError) -> onReady ->
		navigator.geolocation.getCurrentPosition (position) ->
			$log.debug "Gotta GMap Location: #{angular.toJson position}"
			onSuccess
				latitude: position.coords.latitude
				longitude: position.coords.longitude
		, (error) ->
			$log.error "GMap Location Error: #{angular.toJson error}"
			onError error.message if onError
		,
			maximumAge: 3000
			timeout: 5000
			enableHighAccuracy: true
	onDiv: (scope, name, success, center) -> onReady ->
		clear()
		if center
			store.gmap.setZoom 10
			store.gmap.setCenter new plugin.google.maps.LatLng(center.latitude, center.longitude)
			marker(true) center
		else
			store.gmap.getCameraPosition (camera) ->
				$log.debug "Camera Position: #{angular.toJson camera}"
				if camera.zoom is 2 and camera.target.lat is 0 and camera.target.lng is 0
					store.gmap.setZoom 10
					store.gmap.getMyLocation (location) ->
						$log.debug "Gotta GMap Location: #{angular.toJson location}"
						store.gmap.setCenter location.latLng
					, (error) ->
						$log.error "GMap Location Error: #{angular.toJson error}"
		div = document.getElementById name
		store.gmap.setDiv div
		store.gmap.setMapTypeId store.map_type
		store.gmap.setClickable true
		scope.$watch ->
			!!$ionicSideMenuDelegate.isOpenLeft()
		, menuShown
		success store.gmap if success
	onTap: (proc) -> onReady ->
		$log.debug "GMap onTap is changed: #{proc}"
		store.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) ->
			$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{proc}"
			proc
				latitude: latLng.lat
				longitude: latLng.lng
