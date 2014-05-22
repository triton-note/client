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
