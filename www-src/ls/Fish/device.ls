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
