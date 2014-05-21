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

.factory 'RecordFactory', ->
	/*
		Load records from server
	*/
	load: -> [ # Pseudo list
		{
			image: "http://upload.wikimedia.org/wikipedia/commons/e/ec/John_W._Lewin_-_Fish_catch_and_Dawes_Point%2C_Sydney_Harbour_-_Google_Art_Project.jpg"
			fishes:
				{name: "Dolphin", count: 2}
				{name: "Whale", count: 1}
		}
		{
			image: "http://eofdreams.com/data_images/dreams/fish/fish-09.jpg"
			fishes:
				{name: "Snapper", count: 3}
				{name: "Manta", count: 0}
		}
	]
