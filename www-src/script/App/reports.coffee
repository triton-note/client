angular.module('triton_note.reports', [])
.factory 'ConditionFactory', ($log, ServerFactory, AccountFactory, UnitFactory) ->
	moon = (n) ->
		v = "0#{n}".split('').reverse()[..1].reverse().join('')
		"img/moon/phase-#{v}.png"
	tide = (name) ->
		name: name
		icon: "img/tide/#{name.toLowerCase()}.png"
	weather = (id) ->
		"http://openweathermap.org/img/w/#{id}.png"
	default_condition = -> angular.copy
		moon: 0
		tide: 'High'
		weather:
			name: 'Clear'
			icon_url: weather('01d')
			temperature:
				value: 20
				unit: 'Cels'

	state: (datetime, geoinfo, taker) ->
		$log.debug "Taking tide and moon phase at #{angular.toJson geoinfo} #{datetime}"
		AccountFactory.with_ticket (ticket)->
			ServerFactory.conditions ticket, datetime, geoinfo
		, (condition) ->
			$log.debug "Get condition: #{angular.toJson condition}"
			if !condition.weather
				condition.weather = default_condition().weather
			taker condition
		, (error) ->
			$log.error "Failed to get conditions from server: #{error}"
			taker default_condition()
	moon_phases: [0..30].map moon
	tide_phases: ['Flood', 'High', 'Ebb', 'Low'].map tide
	weather_states: _.Obj.map weather,
		Clear: '01d'
		Clouds: '04d'
		Rain: '09d'
		Snow: '13d'

.factory 'ReportFactory', ($log, $filter, $interval, $ionicPopup, SocialFactory, AccountFactory, ServerFactory, DistributionFactory) ->
	limit = 30
	expiration = 50 * 60 * 1000 # 50 minutes
	store =
		current:
			index: null
			###
				id: String (Can be Empty, but not NULL)
				user_id: String (Can be Empty, but not NULL)
				photo:
					original: String (URL)
					mainview: String (URL)
					thumbnail: String (URL)
				dateAt: Date
				location:
					name: String
					geoinfo:
						latitude: Double
						longitude: Double
				comment: String
				fishes: List of ...
					name: String
					count: Int
					length:
						value: Double
						unit: 'inch'|'cm'
					weight:
						value: Double
						unit: 'pond'|'kg'
				condition:
					moon: Int
					tide: String
					weather:
						name: String
						icon_url: String (URL)
						temperature:
							value: Double
							unit: 'Cels'|'Fahr'
			###
			report: null
		###
		List of
			timestamp: Long (DateTime)
			report: Report
		###
		reports: []
		hasMore: true

	loadServer = (success) ->
		last_id = store.reports[store.reports.length - 1]?.report?.id ? null
		count = if last_id then limit else 10
		$log.info "Loading from server: #{count} from #{last_id}: cached list: #{angular.toJson store.reports}"
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.load_reports ticket, count, last_id
		, (list) ->
			more = save list
			store.reports = store.reports ++ more
			store.hasMore = count <= more.length
			$log.info "Loaded #{more.length} reports, Set hasMore = #{store.hasMore}"
			success?()
		, (error) ->
			$log.error "Failed to load from server: #{angular.toJson error}"
			$ionicPopup.alert
				title: "Failed to load from server"
				template: ""
			success?()

	reload = (success) ->
		store.reports = []
		loadServer success

	# reload every 6 hours
	$interval ->
		reload()
	, 6 * 60 * 60 * 1000

	save = (list) ->
		now = new Date().getTime()
		list.map (report) ->
			report.dateAt = new Date(report.dateAt) if not (report.dateAt instanceof Date)
			timestamp: now
			report: report

	read = (item) ->
		now = new Date().getTime()
		past = now - item.timestamp
		$log.debug "Report timestamp past: #{past}ms"
		if expiration < past
			AccountFactory.with_ticket (ticket) ->
				ServerFactory.read_report ticket, item.report.id
			, (result) ->
				$log.debug "Read report: #{angular.toJson result}"
				item.timestamp = now
				angular.copy result.report, item.report
			, (error) ->
				$log.error "Failed to read report(#{item.report.id}) from server: #{angular.toJson error}"
		item.report

	cachedList: ->
		store.reports.map read
	hasMore: ->
		store.hasMore
	###
		Get index of list by report id
	###
	getIndex: (id) ->
		store.reports.map((v) -> v.report.id is id).indexOf true
	###
		Refresh cache
	###
	refresh: reload
	clear_list: ->
		store.reports = []
		store.hasMore = true
	###
		Load reports from server
	###
	load: loadServer
	###
		Get a report by index of cached list
	###
	getReport: (index) ->
		$log.debug "Getting report[#{index}]"
		store.current.index = index
		store.current.report = angular.copy read store.reports[index]
	current: ->
		store.current
	clear_current: ->
		$log.debug "Report current clear()"
		store.current =
			index: null
			report: null
	newCurrent: (photo_uri, timestamp, geoinfo) ->
		report =
			photo:
				mainview:
					volatile_url: photo_uri
			dateAt: timestamp
			location:
				name: null
				geoinfo: geoinfo
			fishes: []
			comment: ""
		store.current =
			index: null
			report: report
		report
	###
		Add report
	###
	add: (report) ->
		store.reports = save([report]) ++ store.reports
		DistributionFactory.report.add report
	###
		Remove report specified by index
	###
	remove: (index, success) ->
		removing_id = store.reports[index].report.id
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.remove_report ticket, removing_id
		, ->
			$log.info "Deleted report: #{removing_id}"
			DistributionFactory.report.remove removing_id
			store.reports.splice(index, 1)
			success()
		, (error) ->
			$ionicPopup.alert
				title: "Failed to remove from server"
				template: error.msg
	###
		Update report
	###
	updateByCurrent: (success, on_finally) ->
		if store.current.report?.id
			AccountFactory.with_ticket (ticket) ->
				ServerFactory.update_report ticket, store.current.report
			, ->
				$log.info "Updated report: #{store.current.report.id}"
				store.reports[store.current.index] = save([store.current.report])[0]
				DistributionFactory.report.update store.current.report
				success()
				on_finally()
			, (error) ->
				$ionicPopup.alert
					title: "Failed to update to server"
					template: error.msg
				on_finally()
	###
		Publish to Facebook
	###
	publish: (report_id, on_success, on_error) ->
		SocialFactory.publish (token) ->
			AccountFactory.with_ticket (ticket) ->
				ServerFactory.publish_report ticket, report_id, token
			, ->
				$log.info "Success to publish report: #{report_id}"
				on_success()
			, on_error
		, (error) ->
			$ionicPopup.alert
				title: 'Rejected'
				template: error
			.then (res) ->
				on_error "Rejected by user"


.factory 'UnitFactory', ($log, AccountFactory, ServerFactory) ->
	inchToCm = 2.54
	pondToKg = 0.4536
	default_units =
		length: 'cm'
		weight: 'kg'
		temperature: 'Cels'

	store =
		unit: null

	save_current = (units) ->
		store.unit = angular.copy units
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.update_measures ticket, units
		, -> $log.debug "Success to change units"
		, (error) -> $log.debug "Failed to change units: #{angular.toJson error}"
	load_local = -> store.unit ? default_units
	load_server = (taker) ->
		$log.debug "Loading account units"
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.load_measures ticket
		, (units) ->
			$log.debug "Loaded account units: #{angular.toJson units}"
			store.unit = angular.copy units
			taker units
		, (error) ->
			$log.error "Failed to load account units: #{angular.toJson error}"
			taker(angular.copy default_units)
	load_current = (taker) ->
		if (unit = store.unit)
		then taker(angular.copy unit)
		else load_server taker
	init = ->
		unless store.unit
			load_server (units) ->
				$log.debug "Refresh units: #{angular.toJson units}"
	ionic.Platform.ready init

	units: -> angular.copy
		length: ['cm', 'inch']
		weight: ['kg', 'pond']
		temperature: ['Cels', 'Fahr']
	load: load_current
	save: save_current
	length: (src) ->
		init()
		dst_unit = load_local().length
		convert = -> switch src.unit
			when dst_unit then src.value
			when 'inch'   then src.value * inchToCm
			when 'cm'     then src.value / inchToCm
		{
			value: convert()
			unit: dstUnit
		}
	weight: (src) ->
		init()
		dst_unit = load_local().weight
		convert = -> switch src.unit
			when dst_unit then src.value
			when 'pond'   then src.value * pondToKg
			when 'kg'     then src.value / pondToKg
		{
			value: convert()
			unit: dstUnit
		}
	temperature: (src) ->
		init()
		dst_unit = load_local().temperature
		convert = -> switch src.unit
			when dst_unit then src.value
			when 'Cels'   then src.value * 9 / 5 + 32
			when 'Fahr'   then (src.value - 32) * 5 / 9
		{
			value: convert()
			unit: dst_unit
		}

.factory 'DistributionFactory', ($log, $interval, $ionicPopup, AccountFactory, ServerFactory) ->
	store =
		###
		List of
			report_id: String (only if mine)
			name: String
			count: Int
			date: Date
			geoinfo:
				latitude: Double
				longitude: Double
		###
		catches:
			mine: null
			others: null
		###
		List of
			name: String
			count: Int
		###
		names: null

	convert = (fish) ->
		fish.date = new Date(fish.date)
		fish
	refresh_mine = (success) ->
		$log.debug "Refreshing distributions of mine ..."
		suc = ->
			success() if success
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.catches_mine ticket
		, _.map(convert) >> (list) ->
			store.catches.mine = list
			suc()
		, (error) ->
			$ionicPopup.alert
				title: "Error"
				template: "Failed to load catches list"
			.then ->
				suc()
	refresh_others = (success) ->
		$log.debug "Refreshing distributions of others ..."
		suc = ->
			success() if success
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.catches_others ticket
		, _.map(convert) >> (list) ->
			store.catches.others = list
			suc()
		, (error) ->
			$ionicPopup.alert
				title: "Error"
				template: "Failed to load catches list"
			.then ->
				suc()
	refresh_names = (success) ->
		$log.debug "Refreshing distributions of names ..."
		suc = ->
			success() if success
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.catches_names ticket
		, (list) ->
			store.names = list
			suc()
		, (error) ->
			suc()

	$interval ->
		refresh_mine()
		refresh_others()
		refresh_names()
	, 6 * 60 * 60 * 1000

	remove_mine = (report_id) ->
		$log.debug "Removing distribution of report id:#{report_id}"
		if (list = store.catches.mine)
			store.catches.mine = list.filter (v) -> v.report_id isnt report_id
	add_mine = (report) ->
		if (mine = store.catches.mine)
			list = report.fishes.map (fish) ->
				report_id: report.id
				name: fish.name
				count: fish.count
				date: report.dateAt
				geoinfo: report.location.geoinfo
			store.catches.mine = mine ++ list
			$log.debug "Added distribution of catches:#{angular.toJson list}"

	startsWith = (word, pre) ->
		word.toUpperCase().indexOf(pre) is 0

	report:
		add: add_mine
		remove: remove_mine
		update: (report) ->
			remove_mine report.id
			add_mine report
	name_suggestion: (pre_name, success) ->
		check_or = (fail) ->
			if (src = store.names)
				pre = pre_name?.toUpperCase()
				list = if pre then src.filter ((a) -> startsWith(a, pre)) else []
				success list.sort((a, b) -> a.count - b.count).reverse().map((v) -> v.name)
			else fail()
		check_or ->
			refresh_names ->
				check_or ->
					success []
	mine: (pre_name, success) ->
		check_or = (fail) ->
			if (src = store.catches.mine)
				pre = pre_name?.toUpperCase()
				list = if pre then src.filter ((a) -> startsWith(a.name, pre))	else src
				success list.sort((a, b) -> a.count - b.count).reverse()
			else fail()
		check_or ->
			refresh_mine ->
				check_or ->
					success []
	others: (pre_name, success) ->
		check_or = (fail) ->
			if (src = store.catches.others)
				pre = pre_name?.toUpperCase()
				list = if pre then	src.filter ((a) -> startsWith(a.name, pre)) else src
				success list.sort((a, b) -> a.count - b.count).reverse()
			else fail()
		check_or ->
			refresh_others ->
				check_or ->
					success []
