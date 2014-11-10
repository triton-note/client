.factory 'ServerFactory', ($log, $http, $ionicPopup, serverURL) ->
	url = (path) -> "#{serverURL}/#{path}"
	retryable = (retry, config, res-taker, error-taker) !->
		$http config
		.success (data, status, headers, config) !-> res-taker data
		.error (data, status, headers, config) !->
			$log.error "Error on request:#{angular.toJson config} => (#{status})#{data}"
			error = http-error.gen status, data
			if error.type == http-error.types.error && retry > 0
			then retryable retry - 1, config, res-taker, error-taker
			else error-taker error
	http = (method, path, data = null, content-type = "text/json") -> (res-taker, error-taker, retry = 3) !->
		retryable retry,
			method: method
			url: url(path)
			data: data
			headers:
				if data
				then 'Content-Type': content-type
				else {}
		, res-taker, error-taker

	http-error =
		types:
			fatal: 'Fatal'
			error: 'Error'
			expired: 'Expired'
		gen: (status, data) -> switch status
		| 400 =>
			if data.indexOf('Expired') > -1 then
				type: @types.expired
				msg: "Token Expired"
			else
				type: @types.Error
				msg: "Application Error"
		| 404 =>
			type: @types.fatal
			msg: "Not Found"
		| 501 =>
			type: @types.fatal
			msg: "Not Implemented"
		| 503 =>
			type: @types.fatal
			msg: "Service Unavailable"
		| _   =>
			type: @types.error
			msg: "Error"

	error-types: http-error.types
	/*
	Load the 'terms of use and disclaimer' from server
	*/
	terms-of-use: (taker) !->
		http('GET', "assets/terms-of-use.txt") taker, (error) !->
			$ionicPopup.alert do
				title: 'Server Error'
				template: error.msg
				ok-text: "Exit"
				ok-type: "button-stable"
			.then (res) !-> ionic.Platform.exitApp!
	/*
	Login to Server
	*/
	login: (token, ticket-taker, error-taker) !->
		way = 'facebook'
		$log.debug "Login to server with #{way} by #{token}"
		http('POST', "login/#{way}",
			token: token
		) ticket-taker, error-taker
	/*
	Connect account to social service
	*/
	connect: (ticket, token) -> (success-taker, error-taker) !->
		way-name = 'facebook'
		$log.debug "Connecting to #{way-name} by token:#{token}"
		http('POST', "account/connect/#{ticket}",
			way: way-name
			token: token
		) success-taker, error-taker
	/*
	Disconnect account to social service
	*/
	disconnect: (ticket) -> (success-taker, error-taker) !->
		way-name = 'facebook'
		$log.debug "Disconnecting from #{way-name}"
		http('POST', "account/disconnect/#{ticket}",
			way: way-name
		) success-taker, error-taker
	/*
	Get start session by server, then pass to taker
	*/
	start-session: (ticket, geoinfo) -> (session-taker, error-taker) !->
		$log.debug "Starting session by #{ticket} on #{angular.toJson geoinfo}"
		http('POST', "report/new-session/#{ticket}",
			geoinfo: geoinfo
		) session-taker, error-taker
	/*
	Put a photo which is encoded by base64 to session
	*/
	put-photo: (session, ...photos) -> (success-taker, error-taker) !->
		$log.debug "Putting a photo with #{session}: #{photos}"
		http('POST', "report/photo/#{session}",
			names: photos
		) success-taker, error-taker
	/*
	Put a photo which is encoded by base64 to session
	*/
	infer-photo: (session) -> (success-taker, error-taker) !->
		$log.debug "Inferring a photo with #{session}"
		http('GET', "report/infer/#{session}") success-taker, error-taker
	/*
	Put given report to the session
	*/
	submit-report: (session, report) -> (success, error-taker) !->
		$log.debug "Submitting report with #{session}: #{angular.toJson report}"
		http('POST', "report/submit/#{session}",
			report: report
		) success, error-taker
	/*
	Put given report to the session
	*/
	publish-report: (session, token) -> (success, error-taker) !->
		$log.debug "Publishing report with #{session}: #{token}"
		http('POST', "report/publish/#{session}",
			publishing:
				way: 'facebook'
				token: token
		) success, error-taker
	/*
	Load report from server, then pass to taker
	*/
	load-reports: (ticket, count, last-id) -> (taker, error-taker) !->
		$log.debug "Loading #{count} reports from #{last-id}"
		http('POST', "report/load/#{ticket}",
			count: count
			last: last-id
		) taker, error-taker
	/*
	*/
	read-report: (ticket, id) -> (taker, error-taker) !->
		$log.debug "Reading report(id:#{id})"
		http('POST', "report/read/#{ticket}",
			id: id
		) taker, error-taker
	/*
	Remove report from server
	*/
	remove-report: (ticket, id) -> (success, error-taker) !->
		$log.debug "Removing report(#{id})"
		http('POST', "report/remove/#{ticket}",
			id: id
		) success, error-taker
	/*
	Update report to server. ID has to be contain given report.
	*/
	update-report: (ticket, report) -> (success, error-taker) !->
		$log.debug "Updating report: #{angular.toJson report}"
		http('POST', "report/update/#{ticket}",
			report: report
		) success, error-taker
	/*
	Load units in account settings
	*/
	load-units: (ticket) -> (success, error-taker) !->
		$log.debug "Loading unit"
		http('GET', "account/unit/load/#{ticket}") success, error-taker
	/*
	Update units in account settings
	*/
	change-units: (ticket, unit) -> (success, error-taker) !->
		$log.debug "Changing unit: #{angular.toJson unit}"
		http('POST', "account/unit/change/#{ticket}",
			unit: unit
		) success, error-taker
	/*
	Load distributions of own catches
	*/
	catches-mine: (ticket) -> (success, error-taker) !->
		$log.debug "Retrieving my cathces distributions"
		http('GET', "distribution/mine/#{ticket}") success, error-taker
	/*
	Load distributions of all catches that includes others
	*/
	catches-others: (ticket) -> (success, error-taker) !->
		$log.debug "Retrieving others cathces distributions"
		http('GET', "distribution/others/#{ticket}") success, error-taker
	/*
	Load names of catches with it's count
	*/
	catches-names: (ticket) -> (success, error-taker) !->
		$log.debug "Retrieving names of catches"
		http('GET', "distribution/names/#{ticket}") success, error-taker

.factory 'AcceptanceFactory', ($log, $rootScope, $ionicModal, $ionicPopup, LocalStorageFactory, ServerFactory) ->
	store =
		taking: null

	scope = $rootScope.$new(true)
	scope.accept = !->
		$log.info "Acceptance obtained"
		LocalStorageFactory.acceptance.save true
		scope.modal.remove!
		successIt!
	scope.reject = !->
		$ionicPopup.alert do
			title: "Good Bye !"
			ok-text: "Exit"
			ok-type: "button-stable"
		.then (res) !->
			ionic.Platform.exitApp!

	successIt = !->
		if store.taking
			store.taking = null
			for suc in that
				suc!
	takeIt = !->
		if LocalStorageFactory.acceptance.load!
		then successIt!
		else ServerFactory.terms-of-use (text) !->
			scope.terms-of-use = text
			$log.warn "Taking Acceptance ..."
			$ionicModal.fromTemplateUrl 'template/terms-of-use.html'
			, (modal) !->
				scope.modal = modal
				modal.show!
			,
				scope: scope
				animation: 'slide-in-up'
	obtain: (success) !->
		if store.taking
			taking.push success
		else
			store.taking = [success]
			takeIt!

.factory 'SocialFactory', ($log) ->
	facebook-login = (...perm) -> (token-taker, error-taker) !->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login perm
		, (result) !->
			$log.debug "Get access: #{angular.toJson result}"
			facebook-profile (profile) !->
				token-taker profile, result.authResponse.accessToken
			, error-taker
		, error-taker
	facebook-profile = (profile-taker, error-taker) !->
		$log.info "Getting profile of Facebook"
		facebookConnectPlugin.api "me?fields=name", ['public_profile']
		, (info) !->
			$log.debug "Get profile: #{angular.toJson info}"
			profile-taker do
				id: info.id
				name: info.name
		, error-taker
	facebook-disconnect = (onSuccess, error-taker) !->
		$log.info "Disconnecting from facebook"
		facebookConnectPlugin.api "me/permissions?method=delete", []
		, (info) !->
			$log.debug "Revoked: #{angular.toJson info}"
			facebookConnectPlugin.logout (out) !->
				$log.debug "Logout: #{angular.toJson out}"
				onSuccess!
			, error-taker
		, error-taker

	login: facebook-login 'public_profile'
	publish: facebook-login 'publish_actions'
	disconnect: facebook-disconnect

.factory 'AccountFactory', ($log, $rootScope, $ionicModal, AcceptanceFactory, LocalStorageFactory, ServerFactory, SocialFactory) ->
	store =
		taking: null
		ticket: null

	scope = $rootScope.$new(true)
	accept-account = (taker) !->
		if LocalStorageFactory.account.load!?.id then taker!
		else AcceptanceFactory.obtain !->
			$log.warn "Taking Login Account ..."
			scope.signin = !->
				scope.modal.remove!
				taker!
			$ionicModal.fromTemplateUrl 'template/signin.html'
			, (modal) !->
				scope.modal = modal
				modal.show!
			,
				scope: scope
				animation: 'slide-in-up'

	stack-login = (ticket-taker, error-taker) !->
		if store.ticket then ticket-taker store.ticket
		else
			if store.taking
				that.push ticket-taker
				$log.debug "Pushed into queue: #{that}"
			else
				store.taking = [ticket-taker]
				$log.debug "First listener in queue: #{store.taking}"
				accept-account !->
					$log.debug "Get login"
					connect (token) !->
						ServerFactory.login token
						, (ticket) !->
							store.ticket = ticket
							if store.taking
								$log.debug "Clear and invoking all listeners: #{store.taking}"
								store.taking = null
								for t in that
									t ticket
						, (error) !->
							if error.type != ServerFactory.error-types.fatal
								error-taker error.msg
					, error-taker

	with-ticket = (ticket-proc, success-taker, error-taker) !->
		$log.debug "Getting ticket for: #{ticket-proc}, #{success-taker}"
		auth = !->
			stack-login (ticket) ->
				ticket-proc(ticket) success-taker, (error) !->
					if error.type == ServerFactory.error-types.expired
					then
						store.ticket = null
						auth!
					else error-taker error.msg
			, error-taker
		auth!

	connect = (token-taker, error-taker) !->
		SocialFactory.login (profile, token) !->
			LocalStorageFactory.account.save profile
			$log.info "Social connected."
			token-taker token
		, error-taker

	disconnect = (success-taker, error-taker) !->
		account = LocalStorageFactory.account.load!
		if account?.id
			$log.warn "Social Disconnecting..."
			with-ticket (ticket) ->
				ServerFactory.disconnect ticket
			, (result) !->
				SocialFactory.disconnect !->
					LocalStorageFactory.account.remove!
					$log.info "Social disconnected."
					success-taker!
				, error-taker
			, error-taker
		else
			error-taker "Not connected"

	with-ticket: with-ticket
	connect: (success-taker, error-taker) !->
		connect (token) !->
			with-ticket (ticket) ->
				ServerFactory.connect ticket, token
			, (result) !->
				username = LocalStorageFactory.account.load!?.name
				success-taker name
			, error-taker
		, error-taker
	disconnect: (success-taker, error-taker) !->
		disconnect success-taker, error-taker
	is-connected: ->
		!!LocalStorageFactory.account.load!?.id
	get-username: (success-taker, error-taker) !->
		if LocalStorageFactory.account.load!
			success-taker that.name
		else
			error-taker "Not login"

.factory 'SessionFactory', ($log, $ionicPopup, ServerFactory, SocialFactory, ReportFactory, AccountFactory) ->
	store =
		session: null
		upload-info: null

	permit-publish = (token-taker, error-taker) !->
		SocialFactory.publish token-taker, error-taker

	publish = (session) !->
		permit-publish (account-name, token) !->
			ServerFactory.publish-report(session, token) !->
				$log.info "Success to publish session: #{session}"
			, (error) !->
				$ionicPopup.alert do
					title: 'Error'
					template: "Failed to publish"
		, (error) !->
			$ionicPopup.alert do
				title: 'Rejected'
				template: error

	submit = (session, report, success) !->
		ServerFactory.submit-report(session, report) (report-id) !->
			report.id = report-id
			ReportFactory.add report
			success!
		, (error) !->
			store.session = null
			$ionicPopup.alert do
				title: 'Error'
				template: error.msg

	upload = (uri, success, error) !->
		filename = _.head _.reverse uri.toString!.split('/')
		new FileTransfer().upload uri, store.upload-info.url
			, (e) !->
				$log.info "Success to upload: #{angular.toJson e}"
				success filename
			, (e) !->
				$log.error "Failed to upload: #{angular.toJson e}"
				error e
			,
				fileKey: 'file'
				fileName: filename
				mimeType: 'image/jpeg'
				chunkedMode: false
				params: angular.copy store.upload-info.params

	start: (geoinfo, success, error-taker) !->
		store.session = null
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.start-session ticket, geoinfo
		, (result) !->
			store.session = result.session
			store.upload-info = result.upload
			success!
		, error-taker
	put-photo: (uri, success, inference-taker, error-taker) !->
		if store.session
			upload uri
				, (filename)!->
					ServerFactory.put-photo(that, filename) (urls) !->
						ServerFactory.infer-photo(that) inference-taker, (error) !->
							store.session = null
							error-taker error.msg
						success urls
					, (error) !->
						store.session = null
						error-taker error.msg
				, (error) !->
					error-taker "Failed to upload"
		else error-taker "No session started"
	finish: (report, is-publish, success) !->
		if (session = store.session)
			store.session = null
			submit session, report, !->
				publish(session) if is-publish
				success!
		else 
			$ionicPopup.alert do
				title: 'Error'
				template: "No session started"

.factory 'ReportFactory', ($log, $interval, $ionicPopup, AccountFactory, ServerFactory, DistributionFactory) ->
	limit = 30
	expiration = 50 * 60 * 1000 # 50 minutes
	store =
		/*
		List of
			timestamp: Long (DateTime)
			report:
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

	$interval !->
		reload!
	, 6 * 60 * 60 * 1000

	save = (list) ->
		now = new Date!.getTime!
		_.map (report) ->
			timestamp: now
			report: report
		, list

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

	cachedList: ->
		_.map read, store.reports
	hasMore: ->
		store.hasMore
	/*
		Get index of list by report id
	*/
	getIndex: (id) ->
		_.find-index (.report.id == id), store.reports
	/*
		Get a report by index of cached list
	*/
	getReport: (index) ->
		$log.debug "Getting report[#{index}]"
		read store.reports[index]
	/*
		Clear all cache
	*/
	clear: !->
		store.reports = []
		store.hasMore = true
		$log.debug "Reports cleared."
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
		Add report
	*/
	add: (report) !->
		store.reports = angular.copy(save([report]) ++ store.reports)
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
	update: (report, success) ->
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.update-report ticket, report
		, !->
			$log.info "Updated report: #{report.id}"
			DistributionFactory.report.update report
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
		list = _.map (fish) ->
			report-id: report.id
			name: fish.name
			count: fish.count
			date: report.dateAt
			geoinfo: report.location.geoinfo
		, report.fishes
		if store.catches.mine then
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
				success _.map (.name), _.reverse _.sort-by (.count), list
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
