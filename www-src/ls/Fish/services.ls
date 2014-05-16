.factory 'PostFormFactory', ($window) ->
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

	{
		transform: (obj) -> (_.compact _.flatten resolve obj).join '&'
	}
