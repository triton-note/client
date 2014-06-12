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

.factory 'RecordFactory', ($log, AccountFactory) ->
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

.factory 'ServerFactory', ($log, $http, $ionicPopup) ->
	/*
	Load the 'terms of use and disclaimer' from server
	*/
	terms-of-use: (taker) !->
		taker '
This text is Dammy
'
	/*
	Login to Server
	*/
	login: (way, token, ticket-taker, error-taker) !->
		$log.info "Login to server with #{way} by #{token}"
		ticket-taker "#{way}:#{token}"
	/*
	Get start session by server, then pass to taker
	*/
	start-session: (ticket, session-taker, ticket-timeout) !->
		# Dammy 
	/*
	Command to server to publish the record in session
	*/
	publish: (session, session-timeout) -> (token) !->
		# Dammy
	/*
	Load record from server, then pass to taker
	*/
	load-records: (ticket) -> (offset, count, taker) !->
		# Dammy

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
		save: (v) !->
			value = if v then saver(v) else null
			$log.debug "localStorage['#{name}'] <= #{value}"
			window.localStorage[name] = value
		remove: !->
			window.localStorage.removeItem name

	clear-all: !-> for name in names
		window.localStorage.removeItem name
	/*
	List of String value to express the way of login
	*/
	login-way: make 'login-way', true
	/*
	Boolean value for acceptance of 'Terms Of Use and Disclaimer'
	*/
	acceptance: make 'Acceptance'

.factory 'AccountFactory', ($log, $ionicPopup, LocalStorageFactory, ServerFactory) ->
	ways =
		facebook: 'facebook'
		google: 'google'

	store =
		ticket: null
		session: null

	facebook = (perm, token-taker, error-taker) !->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login [perm]
			, (data) !-> token-taker data.authResponse.accessToken
			, error-taker
	google = (perm, token-taker, error-taker) !->

	getLoginWay = (way-taker) !->
		if LocalStorageFactory.login-way.load! then way-taker that
		else
			$ionicPopup.show {
				template: 'Select for Login'
				buttons:
					{
						text: ''
						type: 'button icon ion-social-facebook button-positive'
						onTap: (e) -> ways.facebook
					},{
						text: ''
						type: 'button icon ion-social-googleplus button-assertive'
						onTap: (e) -> ways.google
					}
			}
			.then way-taker

	doLogin = (token-taker, error-taker) !->
		getLoginWay (way) !-> switch way
		| ways.facebook => facebook 'email', token-taker(way), error-taker
		| _             => ionic.Platform.exitApp!

	doPublish = (token-taker, error-taker) !->
		getLoginWay (way) !-> switch way
		| ways.facebook => facebook 'publish_actions', token-taker, error-taker
		| _             => ionic.Platform.exitApp!
	
	login = (ticket-taker) !->
		action =
			error-taker: (error-msg) !->
				$ionicPopup.alert {
					title: 'Error'
					template: error-msg
				}
				.then (res) !-> @do!
			token-taker: (way-name) -> (token) !->
				LocalStorageFactory.login-way.save way-name
				ServerFactory.login way-name, token, ticket-taker, @error-taker
			do: !-> doLogin @token-taker, @error-taker
		action.do!
	publish = (session) !->
		token-taker = ServerFactory.publish session, !->
			$ionicPopup.alert {
				title: 'Error'
				sub-title: 'Timeout'
				template: "Session is time over."
			}
		doPublish token-taker, (error-msg) !->
			$ionicPopup.confirm {
				title: 'Error'
				sub-title: "Try Again ?"
				template: error-msg
			}
			.then (res) !-> if res
				publish session

	getTicket = (ticket-taker = (t) !-> $log.debug "Ticket: #{t}") !->
		if store.ticket then ticket-taker that
		else
			login (ticket) !->
				store.ticket = ticket
				ticket-taker ticket
	startSession = !->
		unless store.session
			getTicket (ticket) !->
				ServerFactory.startSession ticket
				, (session) !->
					store.session = session
				, !->
					store.ticket = null
					startSession!
	finishSession = !->
		if store.session
			store.session = null
			ServerFactory.put that, record
			isPublish && publish that

	ticket:
		get: getTicket
	session:
		start: startSession
		finish: finishSession

.factory 'AcceptanceFactory', ($log, $ionicPopup, LocalStorageFactory, ServerFactory) ->
	store =
		terms-of-use: null

	terms-of-use: -> store.terms-of-use
	obtain: (success) !->
		if LocalStorageFactory.acceptance.load!
		then success!
		else ServerFactory.terms-of-use (text) !->
			store.terms-of-use = text
			$ionicPopup.confirm {
				title: "Terms of Use and Disclaimer"
				templateUrl: 'template/terms-of-use.html'
			}
			.then (res) !->
				if res then
					LocalStorageFactory.acceptance.save true
					success!
				else
					$ionicPopup.alert {
						title: "Exit"
						template: "Good Bye !"
					}
					.then (res) !->
						ionic.Platform.exitApp!
