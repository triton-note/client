.filter 'fishFilter', ($filter, UnitFactory) ->
	/*
		fish {
			name: String
			count: Int
			length: {
				value: Double
				unit: 'inch'|'cm'
			}
			weight: {
				value: Double
				unit: 'pond'|'kg'
			}
		}
	*/
	(fish, units = {length: 'inch', weight: 'pond'}) ->
		size = (u) ->
			src = eval "fish.#{u}"
			if src then
				dstUnit = eval "units.#{u}"
				converter = eval "UnitFactory.#{u}"
				converted = converter(src.value, src.unit, dstUnit)
				"#{$filter('number')(converted, 0)} #{dstUnit}"
			else []
		sizes = (_.flatten _.map(size) ["length", "weight"]).join ', '
		volume =
			| sizes => "(#{sizes})"
			| _    => ""
		"#{fish.name}#{volume} x #{fish.count}"
