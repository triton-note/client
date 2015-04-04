angular.module('triton_note.filter', [])
.filter 'fishFilter', ($log, $filter, UnitFactory) ->
	###
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
	###
	(fish) ->
		size = (u) ->
			src = eval "fish.#{u}"
			if src?.value
				converter = eval "UnitFactory.#{u}"
				converted = converter(src)
				"#{$filter('number')(converted.value, 0)} #{converted.unit}"
			else null
		sizes = ["length", "weight"].map(size).filter((v) -> !!v).join ', '
		volume = if sizes then "(#{sizes})" else ""
		"#{fish.name}#{volume} x #{fish.count}"

.filter 'temperatureFilter', ($log, $filter, UnitFactory) ->
	(src) -> if !src then "" else
		dst = UnitFactory.temperature(src)
		"#{$filter('number')(dst.value, 1)} °#{dst.unit[0]}"
