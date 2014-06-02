.factory 'PostFormFactory', ($window) ->
	/*
		Transform obj for POST body.
	*/
	transform: (obj) -> 
		encode = $window.encodeURIComponent
		joinValue = (value, name) ->
			| value? => switch
				| name? => "#{encode name}=#{encode value}"
				| _     => "#{encode value}"
			| _         => null

		resolve = (obj, parent = null) ->
			eachValue = (f) ->
				for index, value of obj
					resolve value, if parent
						then "#{parent}#{f(index)}"
						else "#{index}"
			switch
			| obj instanceof Array  => eachValue (i) -> "[#i]"
			| obj instanceof Object => eachValue (i) -> ".#i"
			| _                     => [ joinValue(obj, parent) ]
		(_.compact _.flatten resolve obj).join '&'

.factory 'PhotoFactory', ->
	/*
		Select a photo from storage.
		onSuccess(image-uri)
		onFailure(error-message)
	*/
	select: (onSuccess, onFailure = (msg) !-> alert msg) !->
		navigator.camera.getPicture onSuccess, onFailure,
			sourceType: Camera.PictureSourceType.PHOTOLIBRARY
			destinationType: Camera.DestinationType.FILE_URI

.factory 'RecordFactory', ($log) ->
	loadLocal = ->
		list = angular.fromJson window.localStorage['records'] ? []
		$log.info "Loaded records: #{list}"
		list
	saveLocal = (records) ->
		list = angular.toJson records
		$log.info "Saving records: #{list}"
		window.localStorage['records'] = list
		list
	/*
		Load records from storage
	*/
	load: -> loadLocal!
	/*
		Add record
	*/
	add: (record) -> 
		list = loadLocal!
		list.push record
		saveLocal list
	/*
		Remove record specified by index
	*/
	remove: (index) ->
		list = loadLocal!
		list.splice index, 1
		saveLocal list
	/*
		Update record specified by index
	*/
	update: (index, record) ->
		list = loadLocal!
		list[index] = record
		saveLocal list

.factory 'UnitFactory', ->
	inchToCm = 2.54
	pondToKg = 0.4536
	
	length: (value, srcUnit, dstUnit) -> switch srcUnit
		| dstUnit => value
		| 'inch'  => value * inchToCm
		| 'cm'    => value / inchToCm

	weight: (value, srcUnit, dstUnit) -> switch srcUnit
		| dstUnit => value
		| 'pond'  => value * pondToKg
		| 'kg'    => value / pondToKg

.factory 'GMapFactory', ($log) ->
	store = {
		gmap: null
		marker: null
	}
	create = (center) !->
		store.gmap = plugin.google.maps.Map.getMap {
			mapType: plugin.google.maps.MapTypeId.HYBRID
			controls:
				myLocationButton: true
				zoom: true
		}
		store.gmap.on plugin.google.maps.event.MAP_READY, onReady(center)
	onReady = (center) -> (gmap) !->
		centering = (latLng) !->
			addMarker latLng
			gmap.setCenter latLng
		if center
			centering center
		else gmap.getMyLocation (latLng) !-> centering latLng
		gmap.setZoom 10
		gmap.showDialog!
	addMarker = (latLng) !->
		store.marker?.remove!
		store.gmap.addMarker {
			position: latLng
		}, (marker) !->
			store.marker = marker

	showMap: (center, setter) ->
		if store.gmap
			onReady(center) store.gmap
		else create center

		store.gmap.on plugin.google.maps.event.MAP_CLICK, (latLng) !->
			$log.debug "Map clicked at #{latLng.toUrlValue()} with setter: #{setter}"
			if setter
				setter latLng
				addMarker latLng
		store.gmap.on plugin.google.maps.event.MAP_CLOSE, (e) !->
			$log.debug "Map close: #{e}"
			store.gmap.clear!
			store.gmap.off!

.factory 'LoginFactory', ($log, $ionicPopup) ->
	store =
		email: null
		token: null

	loginFacebook = (setter, errorHandler) !->
		setToken = (token) !->
			$log.debug "Setting access token: #{token}"
			store.token = token
			setter token
		getPermission = ([perm, ...left]: perms) !->
			| _.empty perms => facebookConnectPlugin.getAccessToken setToken, errorHandler
			| _ =>
				$log.info "Logging in to Facebook: #{perm}"
				facebookConnectPlugin.login [perm]
					, (data) !-> getPermission(left)
					, errorHandler
		getPermission ["email", "publish_actions"]

	getToken: (setter, errorHandler) !->
		if store.token
		then setter store.token
		else
			$ionicPopup.show {
				title: "Login"
				buttons: [
					text: "Login with facebook"
					type: "button button-full icon icon-left ion-social-facebook button-positive item"
					onTap: (e) -> "Facebook"
				]
			}
			.then (res) !-> switch res
				| "Facebook" => loginFacebook(setter, errorHandler)
				| _          => $log.error "Unsupported login: #{res}"
