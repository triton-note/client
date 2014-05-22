.filter 'fishFilter', ($filter, UnitFactory) ->
	/*
		fish {
			name: String
			count: Int
			length: Float
			weight: Float
			units: {
				length: 'inch', 'cm'
				weight: 'pond', 'kg'
			}
		}
	*/
	(fish, units = {length: 'inch', weight: 'pond'}) ->
		size = (u) ->
			value = eval "fish.#{u}"
			if value then
				srcUnit = eval "fish.units.#{u}"
				dstUnit = eval "units.#{u}"
				converter = eval "UnitFactory.#{u}"
				converted = converter(value, srcUnit, dstUnit)
				"#{$filter('number')(converted, 0)} #{dstUnit}"
			else []
		sizes = (_.flatten _.map(size) ["length", "weight"]).join ', '
		volume =
			| sizes => "(#{sizes})"
			| _    => ""
		"#{fish.name}#{volume} x #{fish.count}"
