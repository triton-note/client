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

.factory 'RecordFactory', ($log, $ionicPopup, AccountFactory, ServerFactory, LocalStorageFactory) ->
	loadLocal = ->
		LocalStorageFactory.records.load! ? []
	saveLocal = (records) ->
		LocalStorageFactory.records.save records

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
	store =
		gmap: null
		marker: null

	create = (center) !->
		store.gmap = plugin.google.maps.Map.getMap do
			mapType: plugin.google.maps.MapTypeId.HYBRID
			controls:
				myLocationButton: true
				zoom: true
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

.factory 'ServerFactory', ($log, $timeout, $http, $ionicPopup, serverURL) ->
	retryable = (path, retry, proc, res-taker, error-taker) !->
		proc "#{serverURL}/#{path}"
		.success (data, status, headers, config) !-> res-taker data
		.error (data, status, headers, config) !->
			error = http-error.gen status
			if error.type == http-error.types.error && retry > 0
			then retryable path, retry - 1, proc, res-taker, error-taker
			else error-taker error
	get = (path, res-taker, error-taker, retry = 3) !->
		retryable path, retry
			, (url) -> $http.get url
			, res-taker, error-taker
	post = (path, data, res-taker, error-taker, retry = 3) !->
		retryable path, retry
			, (url) -> $http.post url, data
			, res-taker, error-taker

	http-error =
		types:
			fatal: 'Fatal'
			error: 'Error'
			expired: 'Expired'
		gen: (status) -> switch status
		| 404 =>
			type: @types.fatal
			msg: "Not Found"
		| 503 =>
			type: @types.fatal
			msg: "Service Unavailable"
		| _   =>
			type: @types.error
			msg: "Error: #{status}"

	error-types: http-error.types
	/*
	Load the 'terms of use and disclaimer' from server
	*/
	terms-of-use: (taker) !->
		get "assets/terms-of-use.txt", taker, (error) !->
			$ionicPopup.alert do
				title: 'Server Error'
				template: error.msg
				ok-text: "Exit"
				ok-type: "button-stable"
			.then (res) !-> ionic.Platform.exitApp!
	/*
	Login to Server
	*/
	login: (way, token, ticket-taker, error-taker) !->
		$log.debug "Login to server with #{way} by #{token}"
		post "login-byToken",
			way: way
			token: token
		, ticket-taker, error-taker
	/*
	Get start session by server, then pass to taker
	*/
	start-session: (ticket, geolocation, session-taker, error-taker) !->
		$log.debug "Starting session by #{ticket} on #{geolocation}"
		post "record/new-session",
			ticket: ticket
			geoinfo:
				latitude: geolocation?.lat
				longitude: geolocation?.lng
		, session-taker, error-taker
	/*
	Put a photo which is encoded by base64 to session
	*/
	put-photo: (session, photo, inference-taker, error-taker) !->
		$log.debug "Putting a photo with #{session}"
		post "record/photo",
			session: session
			photo: photo
		, anguler.fromJson >> inference-taker, error-taker
	/*
	Put given record to the session
	*/
	put-record: (session, record, success, error-taker) !->
		record-json = angular.toJson record
		$log.debug "Putting record with #{session}: #{record-json}"
		post "record/submit",
			session: session
			record: record-json
		, success, error-taker
	/*
	Command to server to publish the record in session
	*/
	publish: (session, way, token, success, error-taker) -> (token) !->
		$log.debug "Publish with #{way} by #{session} and #{token}"
		post "record/publish",
			session: session
			way: way
			token: token
		, success, error-taker
	/*
	Load record from server, then pass to taker
	*/
	load-records: (ticket) -> (offset, count, taker, error-taker) !->
		$log.debug "Loading #{count} records from #{offset}"
		post "record/load",
			ticket: ticket
			offset: offset
			count: count
		, angular.fromJson >> taker, error-taker

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
	/*
	Cache of catches records as JSON
	*/
	records: make 'catch-records', true

.factory 'SocialFactory', ($log) ->
	facebook = (...perm) -> (token-taker, error-taker) !->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login perm
			, (data) !-> token-taker data.authResponse.accessToken
			, error-taker
	google = (...perm) -> (token-taker, error-taker) !->
		# TODO

	ways:
		facebook: 'facebook'
		google: 'google'
	facebook:
		login: facebook 'email'
		publish: facebook 'publish_actions'
	google:
		login: google 'email'
		publish: google 'publish'

.factory 'SessionFactory', ($log, $ionicPopup, ServerFactory, SocialFactory, RecordFactory, AccountFactory) ->
	store =
		session: null

	doPublish = (way, token-taker, error-taker) !->
		| SocialFactory.ways.facebook => SocialFactory.facebook.publish token-taker, error-taker
		| _             => ionic.Platform.exitApp!

	publish = (session, way) !->
		token-taker = ServerFactory.publish session, way, (error) !->
			switch error.type
			| ServerFactory.error-types.error =>
				$ionicPopup.confirm do
					title: 'Try Again ?'
					template: error.msg
				.then (res) !-> if res
					publish(session, way)
			| _ =>
				$ionicPopup.alert do
					title: 'Error'
					template: error.msg
		doPublish way, token-taker, (error-msg) !->
			$ionicPopup.confirm do
				title: 'Error'
				sub-title: "Try Again ?"
				template: error-msg
			.then (res) !-> if res
				publish session

	start: !->
		unless store.session
			AccountFactory.ticket.get (ticket) !->
				ServerFactory.start-session ticket
				, (session) !->
					store.session = session
				, (error) !->
					switch error.type
					| ServerFactory.error-types.expired =>
						# When ticket is time out
						store.ticket = null
						startSession!
					| _ =>
						$ionicPopup.alert do
							title: 'Error'
							template: error.msg

	finish: (record, publish-ways) !->
		if store.session
			store.session = null
			ServerFactory.put-record that, record
			, !->
				for way in publish-ways ? []
					publish that, way
			, (error) !->
				switch error.type
				| ServerFactory.error-types.error =>
					# When ticket is time out
					store.ticket = null
					startSession!
				| _ =>
					$ionicPopup.alert do
						title: 'Error'
						template: error.msg

.factory 'AccountFactory', ($log, $ionicPopup, LocalStorageFactory, ServerFactory, SocialFactory) ->
	store =
		ticket: null

	getLoginWay = (way-taker) !->
		if LocalStorageFactory.login-way.load! then way-taker that
		else
			$ionicPopup.show do
				template: 'Select for Login'
				buttons:
					{
						text: ''
						type: 'button icon ion-social-facebook button-positive'
						onTap: (e) -> SocialFactory.ways.facebook
					},{
						text: ''
						type: 'button icon ion-social-googleplus button-assertive'
						onTap: (e) -> SocialFactory.ways.google
					}
			.then way-taker

	doLogin = (token-taker, error-taker) !->
		getLoginWay (way) !-> switch way
		| SocialFactory.ways.facebook => SocialFactory.facebook.login token-taker(way), error-taker
		| _             => ionic.Platform.exitApp!

	login = (ticket-taker) !->
		action =
			error-taker: (error-msg) !->
				$ionicPopup.alert do
					title: 'Error'
					template: error-msg
				.then (res) !-> @do!
			token-taker: (way-name) -> (token) !->
				LocalStorageFactory.login-way.save way-name
				ServerFactory.login way-name, token, ticket-taker, (error) !->
					if error.type != ServerFactory.error-types.fatal
						@error-taker error.msg
			do: !-> doLogin @token-taker, @error-taker
		action.do!
	getTicket = (ticket-taker = (t) !-> $log.debug "Ticket: #{t}") !->
		if store.ticket then ticket-taker that
		else
			login (ticket) !->
				store.ticket = ticket
				ticket-taker ticket

	ticket:
		get: getTicket

.factory 'AcceptanceFactory', ($log, $ionicPopup, LocalStorageFactory, ServerFactory) ->
	store =
		terms-of-use: null

	terms-of-use: -> store.terms-of-use
	obtain: (success) !->
		if LocalStorageFactory.acceptance.load!
		then success!
		else ServerFactory.terms-of-use (text) !->
			store.terms-of-use = text
			$ionicPopup.confirm do
				title: "Terms of Use and Disclaimer"
				templateUrl: 'template/terms-of-use.html'
				ok-text: "Accept"
				ok-type: "button-stable"
				cancel-text: "Reject"
				cancel-type: "button-stable"
			.then (res) !->
				if res then
					LocalStorageFactory.acceptance.save true
					success!
				else
					$ionicPopup.alert do
						title: "Good Bye !"
						ok-text: "Exit"
						ok-type: "button-stable"
					.then (res) !->
						ionic.Platform.exitApp!
