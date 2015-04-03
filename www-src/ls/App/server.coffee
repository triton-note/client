angular.module('triton_note.server', ['ionic'])
.factory 'ServerFactory', ($log, $http, $ionicPopup, serverURL) ->
	url = (path) -> "#{serverURL}/#{path}"
	retryable = (retry, config, res_taker, error_taker) -> ionic.Platform.ready ->
		$http config
		.success (data, status, headers, config) -> res_taker data
		.error (data, status, headers, config) ->
			$log.error "Error on request:#{angular.toJson config} => (#{status})#{data}"
			error = http_error.gen status, data
			if error.type is http_error.types.error and retry > 0
			  retryable retry - 1, config, res_taker, error_taker
			else
				error_taker error
	http = (method, path, data = null, content_type = "text/json") -> (res_taker, error_taker, retry = 3) ->
		retryable retry,
			method: method
			url: url(path)
			data: data
			headers:
				if data
				then 'Content-Type': content_type
				else {}
		, res_taker, error_taker

	http_error =
		types:
			fatal: 'Fatal'
			error: 'Error'
			expired: 'Expired'
		gen: (status, data) -> switch status
			when 400 then (
				if data.indexOf('Expired') > -1
					type: @types.expired
					msg: "Token Expired"
				else
					type: @types.error
					msg: "Application Error"
			)
			when 404 then {
				type: @types.fatal
				msg: "Not Found"
			}
			when 501 then {
				type: @types.fatal
				msg: "Not Implemented"
			}
			when 503 then {
				type: @types.fatal
				msg: "Service Unavailable"
			}
			else
				type: @types.error
				msg: "Error"

	error_types: angular.copy http_error.types

	###
	Login to Server
	###
	login: (accessKey, ticket_taker, error_taker) ->
		way = 'facebook'
		$log.debug "Login to server with #{way} by #{accessKey}"
		http('POST', "login/#{way}",
			accessKey: accessKey
		) ticket_taker, error_taker
	###
	Connect account to social service
	###
	connect: (ticket, accessKey) -> (success_taker, error_taker) ->
		way = 'facebook'
		$log.debug "Connecting to #{way} by token:#{accessKey}"
		http('POST', "account/connect/#{way}",
			ticket: ticket
			accessKey: accessKey
		) success_taker, error_taker
	###
	Disconnect account to social service
	###
	disconnect: (ticket) -> (success_taker, error_taker) ->
		way = 'facebook'
		$log.debug "Disconnecting server from #{way}"
		http('POST', "account/disconnect/#{way}",
			ticket: ticket
		) success_taker, error_taker
	###
	Get start session by server, then pass to taker
	###
	start_session: (ticket, geoinfo) -> (session_taker, error_taker) ->
		$log.debug "Starting session by #{ticket} on #{angular.toJson geoinfo}"
		http('POST', "report/new_session",
			ticket: ticket
			geoinfo: geoinfo
		) session_taker, error_taker
	###
	Put a photo which is encoded by base64 to session
	###
	put_photo: (session, ...photos) -> (success_taker, error_taker) ->
		$log.debug "Putting a photo with #{session}: #{photos}"
		http('POST', "report/photo",
			session: session
			names: photos
		) success_taker, error_taker
	###
	Put a photo which is encoded by base64 to session
	###
	infer_photo: (session) -> (success_taker, error_taker) ->
		$log.debug "Inferring a photo with #{session}"
		http('POST', "report/infer",
			session: session
		) success_taker, error_taker
	###
	Put given report to the session
	###
	submit_report: (session, given_report) -> (success, error_taker) ->
		report = angular.copy given_report
		report.dateAt = report.dateAt.getTime()
		$log.debug "Submitting report with #{session}: #{angular.toJson report}"
		http('POST', "report/submit",
			session: session
			report: report
		) success, error_taker
	###
	Put given report to the session
	###
	publish_report: (ticket, report_id, accessKey) -> (success, error_taker) ->
		$log.debug "Publishing report(#{report_id}) with #{ticket}: #{accessKey}"
		http('POST', "report/publish/facebook",
			ticket: ticket
			id: report_id
			accessKey: accessKey
		) success, error_taker
	###
	Load report from server, then pass to taker
	###
	load_reports: (ticket, count, last_id) -> (taker, error_taker) ->
		$log.debug "Loading #{count} reports from #{last_id}"
		http('POST', "report/load",
			ticket: ticket
			count: count
			last: last_id
		) taker, error_taker
	###
	###
	read_report: (ticket, id) -> (taker, error_taker) ->
		$log.debug "Reading report(id:#{id})"
		http('POST', "report/read",
			ticket: ticket
			id: id
		) taker, error_taker
	###
	Update report to server. ID has to be contain given report.
	###
	update_report: (ticket, given_report) -> (success, error_taker) ->
		report = angular.copy given_report
		report.dateAt = report.dateAt.getTime()
		$log.debug "Updating report: #{angular.toJson report}"
		http('POST', "report/update",
			ticket: ticket
			report: report
		) success, error_taker
	###
	Remove report from server
	###
	remove_report: (ticket, id) -> (success, error_taker) ->
		$log.debug "Removing report(#{id})"
		http('POST', "report/remove",
			ticket: ticket
			id: id
		) success, error_taker
	###
	Load measures in account settings
	###
	load_measures: (ticket) -> (success, error_taker) ->
		$log.debug "Loading measures"
		http('POST', "account/measures/load",
			ticket: ticket
		) success, error_taker
	###
	Update measures in account settings
	###
	update_measures: (ticket, measures) -> (success, error_taker) ->
		$log.debug "Changing measures: #{angular.toJson measures}"
		http('POST', "account/measures/update",
			ticket: ticket
			measures: measures
		) success, error_taker
	###
	Load distributions of own catches
	###
	catches_mine: (ticket) -> (success, error_taker) ->
		$log.debug "Retrieving my cathces distributions"
		http('POST', "distribution/mine",
			ticket: ticket
		) success, error_taker
	###
	Load distributions of all catches that includes others
	###
	catches_others: (ticket) -> (success, error_taker) ->
		$log.debug "Retrieving others cathces distributions"
		http('POST', "distribution/others",
			ticket: ticket
		) success, error_taker
	###
	Load names of catches with it's count
	###
	catches_names: (ticket) -> (success, error_taker) ->
		$log.debug "Retrieving names of catches"
		http('POST', "distribution/names",
			ticket: ticket
		) success, error_taker
	###
	Obtain tide and moon phases
	###
	conditions: (ticket, timestamp, geoinfo) -> (success, error_taker) ->
		$log.debug "Retrieving conditions: #{timestamp}, #{angular.toJson geoinfo}"
		http('POST', "conditions/get",
			ticket: ticket
			date: timestamp.getTime()
			geoinfo: geoinfo
		) success, error_taker

.factory 'AcceptanceFactory', ($log, LocalStorageFactory) ->
	store =
		taking: []

	successIt = ->
		LocalStorageFactory.acceptance.save true
		if store.taking
			store.taking = null
			for suc in that
				suc()

	isReady: LocalStorageFactory.acceptance.load
	obtain: (success) ->
		if @isReady()
			success()
		else
			store.taking.push success
	success: successIt

.factory 'SocialFactory', ($log, LocalStorageFactory) ->
	facebook_login = (...perm) -> (token_taker, error_taker) -> ionic.Platform.ready ->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login perm
		, (result) ->
			$log.debug "Get access: #{angular.toJson result}"
			token_taker result.authResponse.accessToken
		, error_taker
	facebook_profile = (profile_taker, error_taker) -> ionic.Platform.ready ->
		$log.info "Getting profile of Facebook"
		facebookConnectPlugin.api "me?fields=name", ['public_profile']
		, (info) ->
			$log.debug "Get profile: #{angular.toJson info}"
			profile_taker do
				id: info.id
				name: info.name
		, error_taker
	facebook_disconnect = (on_success, error_taker) -> ionic.Platform.ready ->
		$log.info "Disconnecting from facebook"
		facebookConnectPlugin.api "me/permissions?method=delete", []
		, (info) ->
			$log.debug "Revoked: #{angular.toJson info}"
			facebookConnectPlugin.logout (out) ->
				$log.debug "Logout: #{angular.toJson out}"
				on_success()
			, error_taker
		, error_taker

	login: (token_taker, error_taker) -> ionic.Platform.ready ->
		facebookConnectPlugin.getLoginStatus (res) ->
			account = LocalStorageFactory.account.load()
			$log.debug "Facebook Login Status for #{angular.toJson account}: #{angular.toJson res}"
			if res.status is "connected" and (account.id is res.authResponse.userID or not account?.id)
			  token_taker res.authResponse.accessToken
			else
				facebook_login('public_profile') token_taker, error_taker
		, (error) ->
			$log.debug "Failed to get Login Status: #{angular.toJson error}"
			facebook_login('public_profile') token_taker, error_taker
	publish: (token_taker, error_taker) -> ionic.Platform.ready ->
		perm = 'publish_actions'
		facebookConnectPlugin.api "me/permissions", []
		, (res) ->
			$log.debug "Facebook Access Permissions: #{angular.toJson res}"
			pg = res.data.filter (v) -> v.permission is perm and v.status is "granted"
			if (pg.length > 0)
			  facebookConnectPlugin.getAccessToken token_taker, error_taker
			else
			  facebook_login(perm) token_taker, error_taker
		, error_taker
	profile: facebook_profile
	disconnect: facebook_disconnect

.factory 'AccountFactory', ($log, $ionicPopup, AcceptanceFactory, LocalStorageFactory, ServerFactory, SocialFactory) ->
	store =
		taking: null
		ticket: null

	stack_login = (ticket_taker, error_taker) ->
		if store.ticket then ticket_taker store.ticket
		else
			taker =
				ticket: ticket_taker
				error: error_taker
			if store.taking
				that.push taker
				$log.debug "Pushed into queue: #{that}"
			else
				broadcast = (proc) -> if (list = store.taking)
					store.taking = null
					$log.debug "Clear and invoking all listeners: #{list.length}"
					list.forEach proc
				store.taking = [taker]
				$log.debug "First listener in queue: #{taker}"
				AcceptanceFactory.obtain ->
					$log.debug "Get login"
					connect (token) ->
						ServerFactory.login token
						, (ticket) ->
							store.ticket = ticket
							broadcast (v) -> v.ticket ticket
						, (error) ->
							broadcast (v) -> v.error error.msg
					, (error) ->
						broadcast (v) -> v.error error

	with_ticket = (ticket_proc, success_taker, error_taker) ->
		$log.debug "Getting ticket for: #{ticket_proc}, #{success_taker}"
		auth = ->
			stack_login (ticket) ->
				ticket_proc(ticket) success_taker, (error) ->
					if error.type is ServerFactory.error_types.expired
						store.ticket = null
						auth()
					else error_taker error.msg
			, error_taker
		auth()

	connect = (token_taker, error_taker) ->
		SocialFactory.login (token) ->
			SocialFactory.profile (profile) ->
				LocalStorageFactory.account.save profile
				$log.info "Social connected."
				token_taker token
			, error_taker
		, error_taker

	disconnect = (success_taker, error_taker) ->
		account = LocalStorageFactory.account.load()
		if account?.id
			$log.warn "Social Disconnecting..."
			with_ticket (ticket) ->
				ServerFactory.disconnect ticket
			, (result) ->
				SocialFactory.disconnect ->
					LocalStorageFactory.account.remove()
					$log.info "Social disconnected."
					success_taker()
				, error_taker
			, error_taker
		else
			error_taker "Not connected"

	with_ticket: with_ticket
	connect: (success_taker, error_taker) ->
		connect (token) ->
			with_ticket (ticket) ->
				ServerFactory.connect ticket, token
			, (result) ->
				username = LocalStorageFactory.account.load()?.name
				success_taker username
			, error_taker
		, error_taker
	disconnect: (success_taker, error_taker) ->
		disconnect success_taker, error_taker
	get_username: (success_taker, error_taker) ->
		SocialFactory.profile (profile) ->
			LocalStorageFactory.account.save profile
			success_taker profile.name
		, (error) ->
			$log.error "Failed to get user name: #{error}"
			error_taker "Not Login"

.factory 'SessionFactory', ($log, $http, $ionicPopup, ServerFactory, SocialFactory, ReportFactory, AccountFactory) ->
	store =
		session: null
		upload_info: null

	publish = (report_id) ->
		ReportFactory.publish report_id, ->
			$log.debug "Published session: #{store.session}"
		, (error) ->
			$ionicPopup.alert do
				title: 'Error'
				template: "Failed to post"

	submit = (session, report, success, error_taker) ->
		report.id = ""
		report.user_id = ""
		ServerFactory.submit_report(session, report) (report_id) ->
			report.id = report_id
			ReportFactory.add report
			success report_id
		, (error) ->
			$ionicPopup.alert do
				title: 'Error'
				template: error.msg
			error_taker error

	upload = (photo, success, error) ->
		filename = "user_photo"
		$log.info "Posting photo_image(#{photo}) by $http with #{angular.toJson store.upload_info}"
		data = new FormData()
		for name, value of store.upload_info.params
			data.append name, value
		data.append 'file', photo, filename
		$http.post store.upload_info.url, data,
			transformRequest: angular.identity,
			headers:
				'Content-Type': undefined
		.success (data, status, headers, config) ->
			$log.debug "Success to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
			success filename
		.error (data, status, headers, config) ->
			$log.debug "Failed to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
			error status

	start: (geoinfo, success, error_taker) ->
		store.session = null
		AccountFactory.with_ticket (ticket) ->
			ServerFactory.start_session ticket, geoinfo
		, (result) ->
			store.session = result.session
			store.upload_info = result.upload
			success()
		, error_taker
	put_photo: (photo, success, inference_taker, error_taker) ->
		if store.session
			upload photo, (filename) ->
				ServerFactory.put_photo(that, filename) (urls) ->
					ServerFactory.infer_photo(that) inference_taker, (error) ->
						store.session = null
						error_taker error.msg
					success urls
				, (error) ->
					store.session = null
					error_taker error.msg
			, (error) ->
				error_taker "Failed to upload"
		else error_taker "No session started"
	finish: (report, is_publish, success, on_finally) ->
		if (session = store.session)
			submit session, report, (report_id) ->
				store.session = null
				$log.info "Session cleared"
				publish(report_id) if is_publish
				success()
				on_finally()
			, on_finally
		else 
			$ionicPopup.alert do
				title: 'Error'
				template: "No session started"
			on_finally()
