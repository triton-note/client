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
	objMap = (f, obj) ->
		tmp = {}
		Object.keys(obj).forEach (key) ->
			tmp[key] = f(obj[key])
		tmp
	defaultCondition = -> angular.copy
		moon: 0
		tide: 'High'
		weather:
			name: 'Clear'
			iconUrl: weather('01d')
			temperature:
				value: 20
				unit: 'Cels'

	state: (datetime, geoinfo, taker) ->
		$log.debug "Taking tide and moon phase at #{angular.toJson geoinfo} #{datetime}"
		AccountFactory.withTicket (ticket)->
			ServerFactory.conditions ticket, datetime, geoinfo
		, (condition) ->
			$log.debug "Get condition: #{angular.toJson condition}"
			if !condition.weather
				condition.weather = defaultCondition().weather
			taker condition
		, (error) ->
			$log.error "Failed to get conditions from server: #{error}"
			taker defaultCondition()
	moonPhases: [0..30].map moon
	tidePhases: ['Flood', 'High', 'Ebb', 'Low'].map tide
	weatherStates: objMap weather,
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
				userId: String (Can be Empty, but not NULL)
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
						iconUrl: String (URL)
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
		lastId = store.reports[store.reports.length - 1]?.report?.id ? null
		count = if lastId then limit else 10
		$log.info "Loading from server: #{count} from #{lastId}: cached list: #{angular.toJson store.reports}"
		AccountFactory.withTicket (ticket) ->
			ServerFactory.loadReports ticket, count, lastId
		, (list) ->
			more = save list
			store.reports = store.reports.concat more
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
			AccountFactory.withTicket (ticket) ->
				ServerFactory.readReport ticket, item.report.id
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
	clearList: ->
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
	clearCurrent: ->
		$log.debug "Report current clear()"
		store.current =
			index: null
			report: null
	newCurrent: (photoUri, timestamp, geoinfo) ->
		report =
			photo:
				mainview:
					volatileUrl: photoUri
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
		store.reports = save([report]).concat store.reports
		DistributionFactory.report.add report
	###
		Remove report specified by index
	###
	remove: (index, success) ->
		removingId = store.reports[index].report.id
		AccountFactory.withTicket (ticket) ->
			ServerFactory.removeReport ticket, removingId
		, ->
			$log.info "Deleted report: #{removingId}"
			DistributionFactory.report.remove removingId
			store.reports.splice(index, 1)
			success()
		, (error) ->
			$ionicPopup.alert
				title: "Failed to remove from server"
				template: error.msg
	###
		Update report
	###
	updateByCurrent: (success, onFinally) ->
		if store.current.report?.id
			AccountFactory.withTicket (ticket) ->
				ServerFactory.updateReport ticket, store.current.report
			, ->
				$log.info "Updated report: #{store.current.report.id}"
				store.reports[store.current.index] = save([store.current.report])[0]
				DistributionFactory.report.update store.current.report
				success()
				onFinally()
			, (error) ->
				$ionicPopup.alert
					title: "Failed to update to server"
					template: error.msg
				onFinally()
	###
		Publish to Facebook
	###
	publish: (reportId, onSuccess, onError) ->
		SocialFactory.publish (token) ->
			AccountFactory.withTicket (ticket) ->
				ServerFactory.publishReport ticket, reportId, token
			, ->
				$log.info "Success to publish report: #{reportId}"
				onSuccess()
			, onError
		, (error) ->
			$ionicPopup.alert
				title: 'Rejected'
				template: error
			.then (res) ->
				onError "Rejected by user"


.factory 'UnitFactory', ($log, AccountFactory, ServerFactory) ->
	inchToCm = 2.54
	pondToKg = 0.4536
	defaultUnits =
		length: 'cm'
		weight: 'kg'
		temperature: 'Cels'

	store =
		unit: null

	saveCurrent = (units) ->
		store.unit = angular.copy units
		AccountFactory.withTicket (ticket) ->
			ServerFactory.updateMeasures ticket, units
		, -> $log.debug "Success to change units"
		, (error) -> $log.debug "Failed to change units: #{angular.toJson error}"
	loadLocal = -> store.unit ? defaultUnits
	loadServer = (taker) ->
		$log.debug "Loading account units"
		AccountFactory.withTicket (ticket) ->
			ServerFactory.loadMeasures ticket
		, (units) ->
			$log.debug "Loaded account units: #{angular.toJson units}"
			store.unit = angular.copy units
			taker units
		, (error) ->
			$log.error "Failed to load account units: #{angular.toJson error}"
			taker(angular.copy defaultUnits)
	loadCurrent = (taker) ->
		if (unit = store.unit)
		then taker(angular.copy unit)
		else loadServer taker
	init = ->
		unless store.unit
			loadServer (units) ->
				$log.debug "Refresh units: #{angular.toJson units}"
	ionic.Platform.ready init

	units: -> angular.copy
		length: ['cm', 'inch']
		weight: ['kg', 'pond']
		temperature: ['Cels', 'Fahr']
	load: loadCurrent
	save: saveCurrent
	length: (src) ->
		init()
		dstUnit = loadLocal().length
		convert = -> switch src.unit
			when dstUnit then src.value
			when 'inch'   then src.value * inchToCm
			when 'cm'     then src.value / inchToCm
		{
			value: convert()
			unit: dstUnit
		}
	weight: (src) ->
		init()
		dstUnit = loadLocal().weight
		convert = -> switch src.unit
			when dstUnit then src.value
			when 'pond'   then src.value * pondToKg
			when 'kg'     then src.value / pondToKg
		{
			value: convert()
			unit: dstUnit
		}
	temperature: (src) ->
		init()
		dstUnit = loadLocal().temperature
		convert = -> switch src.unit
			when dstUnit then src.value
			when 'Cels'   then src.value * 9 / 5 + 32
			when 'Fahr'   then (src.value - 32) * 5 / 9
		{
			value: convert()
			unit: dstUnit
		}

.factory 'DistributionFactory', ($log, $interval, $ionicPopup, AccountFactory, ServerFactory) ->
	store =
		###
		List of
			reportId: String (only if mine)
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
	refreshMine = (success) ->
		$log.debug "Refreshing distributions of mine ..."
		suc = ->
			success() if success
		AccountFactory.withTicket (ticket) ->
			ServerFactory.catchesMine ticket
		, (list) ->
			store.catches.mine = list.map(convert)
			suc()
		, (error) ->
			$ionicPopup.alert
				title: "Error"
				template: "Failed to load catches list"
			.then ->
				suc()
	refreshOthers = (success) ->
		$log.debug "Refreshing distributions of others ..."
		suc = ->
			success() if success
		AccountFactory.withTicket (ticket) ->
			ServerFactory.catchesOthers ticket
		, (list) ->
			store.catches.others = list.map(convert)
			suc()
		, (error) ->
			$ionicPopup.alert
				title: "Error"
				template: "Failed to load catches list"
			.then ->
				suc()
	refreshNames = (success) ->
		$log.debug "Refreshing distributions of names ..."
		suc = ->
			success() if success
		AccountFactory.withTicket (ticket) ->
			ServerFactory.catchesNames ticket
		, (list) ->
			store.names = list
			suc()
		, (error) ->
			suc()

	$interval ->
		refreshMine()
		refreshOthers()
		refreshNames()
	, 6 * 60 * 60 * 1000

	removeMine = (reportId) ->
		$log.debug "Removing distribution of report id:#{reportId}"
		if (list = store.catches.mine)
			store.catches.mine = list.filter (v) -> v.reportId isnt reportId
	addMine = (report) ->
		if (mine = store.catches.mine)
			list = report.fishes.map (fish) ->
				reportId: report.id
				name: fish.name
				count: fish.count
				date: report.dateAt
				geoinfo: report.location.geoinfo
			store.catches.mine = mine.concat list
			$log.debug "Added distribution of catches:#{angular.toJson list}"

	startsWith = (word, pre) ->
		word.toUpperCase().indexOf(pre) is 0

	report:
		add: addMine
		remove: removeMine
		update: (report) ->
			removeMine report.id
			addMine report
	nameSuggestion: (preName, success) ->
		checkOr = (fail) ->
			if (src = store.names)
				pre = preName?.toUpperCase()
				list = if pre then src.filter ((a) -> startsWith(a, pre)) else []
				success list.sort((a, b) -> a.count - b.count).reverse().map((v) -> v.name)
			else fail()
		checkOr ->
			refreshNames ->
				checkOr ->
					success []
	mine: (preName, success) ->
		checkOr = (fail) ->
			if (src = store.catches.mine)
				pre = preName?.toUpperCase()
				list = if pre then src.filter ((a) -> startsWith(a.name, pre))	else src
				success list.sort((a, b) -> a.count - b.count).reverse()
			else fail()
		checkOr ->
			refreshMine ->
				checkOr ->
					success []
	others: (preName, success) ->
		checkOr = (fail) ->
			if (src = store.catches.others)
				pre = preName?.toUpperCase()
				list = if pre then	src.filter ((a) -> startsWith(a.name, pre)) else src
				success list.sort((a, b) -> a.count - b.count).reverse()
			else fail()
		checkOr ->
			refreshOthers ->
				checkOr ->
					success []
