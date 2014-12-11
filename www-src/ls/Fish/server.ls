.factory 'ServerFactory', ($log, $http, $ionicPopup, serverURL) ->
	url = (path) -> "#{serverURL}/#{path}"
	retryable = (retry, config, res-taker, error-taker) !-> ionic.Platform.ready !->
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
			$ionicModal.fromTemplateUrl 'page/terms-of-use.html'
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
	facebook-login = (...perm) -> (token-taker, error-taker) !-> ionic.Platform.ready !->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login perm
		, (result) !->
			$log.debug "Get access: #{angular.toJson result}"
			token-taker result.authResponse.accessToken
		, error-taker
	facebook-profile = (profile-taker, error-taker) !-> ionic.Platform.ready !->
		$log.info "Getting profile of Facebook"
		facebookConnectPlugin.api "me?fields=name", ['public_profile']
		, (info) !->
			$log.debug "Get profile: #{angular.toJson info}"
			profile-taker do
				id: info.id
				name: info.name
		, error-taker
	facebook-disconnect = (on-success, error-taker) !-> ionic.Platform.ready !->
		$log.info "Disconnecting from facebook"
		facebookConnectPlugin.api "me/permissions?method=delete", []
		, (info) !->
			$log.debug "Revoked: #{angular.toJson info}"
			facebookConnectPlugin.logout (out) !->
				$log.debug "Logout: #{angular.toJson out}"
				on-success!
			, error-taker
		, error-taker

	login: facebook-login 'public_profile'
	publish: facebook-login 'publish_actions'
	profile: facebook-profile
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
			$ionicModal.fromTemplateUrl 'page/signin.html'
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
		SocialFactory.login (token) !->
			SocialFactory.profile (profile) !->
				LocalStorageFactory.account.save profile
				$log.info "Social connected."
				token-taker token
			, error-taker
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
				success-taker username
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

.factory 'SessionFactory', ($log, $http, $ionicPopup, ServerFactory, SocialFactory, ReportFactory, AccountFactory) ->
	store =
		session: null
		upload-info: null

	publish = (session) !->
		SocialFactory.publish (token) !->
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

	upload = (photo, success, error) !->
		filename = "user-photo"
		byFT = (uri) !->
			$log.info "Posting photo-image(#{uri}) by FileTransfer with #{angular.toJson store.upload-info}"
			new FileTransfer().upload uri, store.upload-info.url
			, (e) !->
				$log.info "Success to upload(#{filename}): #{angular.toJson e}"
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
		byHttp = (blob) !->
			$log.info "Posting photo-image(#{blob}) by $http with #{angular.toJson store.upload-info}"
			data = new FormData()
			for name, value of store.upload-info.params
				data.append name, value
			data.append 'file', blob, filename
			$http.post store.upload-info.url, data,
				transformRequest: angular.identity,
				headers:
					'Content-Type': undefined
			.success (data, status, headers, config) !->
				$log.debug "Success to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
				success filename
			.error (data, status, headers, config) !->
				$log.debug "Failed to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
				error status
		photo |> if photo instanceof Blob then byHttp else byFT

	start: (geoinfo, success, error-taker) !->
		store.session = null
		AccountFactory.with-ticket (ticket) ->
			ServerFactory.start-session ticket, geoinfo
		, (result) !->
			store.session = result.session
			store.upload-info = result.upload
			success!
		, error-taker
	put-photo: (photo, success, inference-taker, error-taker) !->
		if store.session
			upload photo, (filename) !->
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
