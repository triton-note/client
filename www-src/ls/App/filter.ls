.filter 'fishFilter', ($log, $filter, UnitFactory) ->
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
	(fish) ->
		size = (u) ->
			src = eval "fish.#{u}"
			if src?.value then
				converter = eval "UnitFactory.#{u}"
				converted = converter(src)
				"#{$filter('number')(converted.value, 0)} #{converted.unit}"
			else []
		sizes = (_.flatten _.map(size) ["length", "weight"]).join ', '
		volume =
			| sizes => "(#{sizes})"
			| _    => ""
		"#{fish.name}#{volume} x #{fish.count}"
