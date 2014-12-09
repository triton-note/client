.factory 'ReportFactory', ($log, $filter, $interval, $ionicPopup, AccountFactory, ServerFactory, DistributionFactory) ->
	limit = 30
	expiration = 50 * 60 * 1000 # 50 minutes
	store =
		current:
			index: null
			/*
				id: String
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
			*/
			report: null
		/*
		List of
			timestamp: Long (DateTime)
			report: Report
		*/
		reports: []
		hasMore: false

	loadServer = (last-id = null, taker) !->
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.load-reports ticket, limit, last-id
		, (list) !->
			taker save list
		, (error) !->
			$ionicPopup.alert do
				title: "Failed to load from server"
				template: error
			.then (res) !-> taker null

	reload = (success) !->
		loadServer null, (more) !->
			store.reports = more
			store.hasMore = limit <= more.length
			success! if success

	ionic.Platform.ready !->
		store.hasMore = true
		# reload every 6 hours
		$interval !->
			reload!
		, 6 * 60 * 60 * 1000

	save = (list) ->
		now = new Date!.getTime!
		list |> _.map (report) ->
			timestamp: now
			report: report

	read = (item) ->
		now = new Date!.getTime!
		past = now - item.timestamp
		$log.debug "Report timestamp past: #{past}ms"
		if expiration < past then
			item.timestamp = now
			AccountFactory.with-ticket (ticket) ->
				ServerFactory.read-report ticket, item.report.id
			, (result) !->
				$log.debug "Read report: #{angular.toJson result}"
				angular.copy result.report, item.report
			, (error) !->
				$log.error "Failed to read report(#{item.report.id}) from server: #{error}"
		item.report

	format-date: (date) ->
		$filter('date') new Date(date), 'yyyy-MM-dd'
	cachedList: ->
		store.reports |> _.map read
	hasMore: ->
		store.hasMore
	/*
		Get index of list by report id
	*/
	getIndex: (id) ->
		_.find-index (.report.id == id), store.reports
	/*
		Refresh cache
	*/
	refresh: reload
	/*
		Load reports from server
	*/
	load: (success) !->
		last-id = store.reports[store.reports.length - 1]?.id ? null
		loadServer last-id, (more) !->
			store.reports = store.reports ++ more
			store.hasMore = limit <= more.length
			$log.info "Loaded #{more.length} reports, Set hasMore = #{store.hasMore}"
			success! if success
	/*
		Get a report by index of cached list
	*/
	getReport: (index) ->
		$log.debug "Getting report[#{index}]"
		store.current.index = index
		store.current.report = angular.copy read store.reports[index]
	current: ->
		store.current
	clear-current: !->
		store.current =
			index: null
			report: null
	newCurrent: (photo-uri = null, geoinfo = null) ->
		report =
			photo:
				mainview: photo-uri
			dateAt: $filter('date') new Date!, 'yyyy-MM-dd'
			location:
				name: null
				geoinfo: geoinfo
			fishes: []
			comment: ""
		store.current =
			index: null
			report: report
		report
	/*
		Add report
	*/
	add: (report) !->
		store.reports = save([report]) ++ store.reports
		DistributionFactory.report.add report
	/*
		Remove report specified by index
	*/
	remove: (index, success) !->
		removing-id = store.reports[index].report.id
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.remove-report ticket, removing-id
		, !->
			$log.info "Deleted report: #{removing-id}"
			DistributionFactory.report.remove removing-id
			store.reports = angular.copy((_.take index, store.reports) ++ (_.drop index + 1, store.reports))
			success!
		, (error) !->
			$ionicPopup.alert do
				title: "Failed to remove from server"
				template: error
	/*
		Update report
	*/
	updateByCurrent: (success) !->
		if store.current.report?.id
			AccountFactory.with-ticket (ticket) ->
				ServerFactory.update-report ticket, store.current.report
			, !->
				$log.info "Updated report: #{store.current.report.id}"
				store.reports[store.current.index] = save([store.current.report])[0]
				DistributionFactory.report.update store.current.report
				success!
			, (error) !->
				$ionicPopup.alert do
					title: "Failed to update to server"
					template: error

.factory 'UnitFactory', ($log, AccountFactory, ServerFactory) ->
	inchToCm = 2.54
	pondToKg = 0.4536
	default-units =
		length: 'cm'
		weight: 'kg'

	store =
		unit: null

	save-current = (units) !->
		store.unit = angular.copy units
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.change-units ticket, units
		, !-> $log.debug "Success to change units"
		, (error) !-> $log.debug "Failed to change units: #{error}"
	load-local = -> store.unit ? default-units
	load-server = (taker) !->
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.load-units ticket
		, (units) !->
			$log.debug "Loaded account units: #{units}"
			store.unit = angular.copy units
			taker units
		, (error) !->
			$log.error "Failed to load account units: #{error}"
			taker(angular.copy default-units)
	load-current = (taker) !->
		if store.unit
		then taker(angular.copy that)
		else load-server taker
	init = !->
		if ! store.unit
		then load-server (units) !->
			$log.debug "Refresh units: #{angular.toJson units}"

	units: -> angular.copy do
		length: ['cm', 'inch']
		weight: ['kg', 'pond']
	load: load-current
	save: save-current
	length: (src) ->
		init!
		dst-unit = load-local!.length
		convert = -> switch src.unit
		| dst-unit => src.value
		| 'inch'   => src.value * inchToCm
		| 'cm'     => src.value / inchToCm
		{
			value: convert!
			unit: dstUnit
		}
	weight: (src) ->
		init!
		dst-unit = load-local!.weight
		convert = -> switch src.unit
		| dst-unit => src.value
		| 'pond'   => src.value * pondToKg
		| 'kg'     => src.value / pondToKg
		{
			value: convert!
			unit: dstUnit
		}

.factory 'DistributionFactory', ($log, $interval, $ionicPopup, AccountFactory, ServerFactory) ->
	store =
		/*
		List of
			report-id: String (only if mine)
			name: String
			count: Int
			date: Date
			geoinfo:
				latitude: Double
				longitude: Double
		*/
		catches:
			mine: null
			others: null
		/*
		List of
			name: String
			count: Int
		*/
		names: null

	refresh-mine = (success) !->
		$log.debug "Refreshing distributions of mine ..."
		suc = !->
			success! if success
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.catches-mine ticket
		, (list) !->
			store.catches.mine = list
			suc!
		, (error) !->
			$ionicPopup.alert do
				title: "Error"
				template: "Failed to load catches list"
			.then !->
				suc!
	refresh-others = (success) !->
		$log.debug "Refreshing distributions of others ..."
		suc = !->
			success! if success
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.catches-others ticket
		, (list) !->
			store.catches.others = list
			suc!
		, (error) !->
			$ionicPopup.alert do
				title: "Error"
				template: "Failed to load catches list"
			.then !->
				suc!
	refresh-names = (success) !->
		$log.debug "Refreshing distributions of names ..."
		suc = !->
			success! if success
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.catches-names ticket
		, (list) !->
			store.names = list
			suc!
		, (error) !->
			suc!

	$interval !->
		refresh-mine!
		refresh-others!
		refresh-names!
	, 6 * 60 * 60 * 1000

	remove-mine = (report-id) !->
		$log.debug "Removing distribution of report id:#{report-id}"
		if store.catches.mine then
			store.catches.mine = _.filter (.report-id != report-id), that
	add-mine = (report) !->
		if store.catches.mine then
			list = report.fishes |> _.map (fish) ->
				report-id: report.id
				name: fish.name
				count: fish.count
				date: report.dateAt
				geoinfo: report.location.geoinfo
			store.catches.mine = that ++ list
			$log.debug "Added distribution of catches:#{angular.toJson list}"

	startsWith = (word, pre) ->
		word.toUpperCase!.indexOf(pre) == 0

	report:
		add: add-mine
		remove: remove-mine
		update: (report) !->
			remove-mine report.id
			add-mine report
	name-suggestion: (pre-name, success) !->
		check-or = (fail) !->
			if store.names then
				src = that
				pre = pre-name?.toUpperCase!
				list = if pre
					then _.filter ((a) -> startsWith(a, pre)), src
					else []
				list |> _.sort-by (.count) |> _.reverse |> _.map (.name) |> success 
			else fail!
		check-or !->
			refresh-names !->
				check-or !->
					success []
	mine: (pre-name, success) !->
		check-or = (fail) !->
			if store.catches.mine then
				src = that
				pre = pre-name?.toUpperCase!
				list = if pre
					then _.filter ((a) -> startsWith(a.name, pre)), src
					else src
				success _.reverse _.sort-by (.count), list
			else fail!
		check-or !->
			refresh-mine !->
				check-or !->
					success []
	others: (pre-name, success) !->
		check-or = (fail) !->
			if store.catches.others then
				src = that
				pre = pre-name?.toUpperCase!
				list = if pre
					then _.filter ((a) -> startsWith(a.name, pre)), src
					else src
				success _.reverse _.sort-by (.count), list
			else fail!
		check-or !->
			refresh-others !->
				check-or !->
					success []
