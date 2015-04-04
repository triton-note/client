angular.module('triton_note.server', [])
.factory 'ServerFactory', ($log, $http, $ionicPopup, serverURL) ->
	url = (path) -> "#{serverURL}/#{path}"
	retryable = (retry, config, resTaker, errorTaker) -> ionic.Platform.ready ->
		$http config
		.success (data, status, headers, config) -> resTaker data
		.error (data, status, headers, config) ->
			$log.error "Error on request:#{angular.toJson config} => (#{status})#{data}"
			error = httpError.gen status, data
			if error.type is httpError.types.error and retry > 0
			  retryable retry - 1, config, resTaker, errorTaker
			else
				errorTaker error
	http = (method, path, data = null, contentType = "text/json") -> (resTaker, errorTaker, retry = 3) ->
		retryable retry,
			method: method
			url: url(path)
			data: data
			headers:
				if data
				then 'Content-Type': contentType
				else {}
		, resTaker, errorTaker

	httpError =
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

	errorTypes: angular.copy httpError.types

	###
	Login to Server
	###
	login: (accessKey, ticketTaker, errorTaker) ->
		way = 'facebook'
		$log.debug "Login to server with #{way} by #{accessKey}"
		http('POST', "login/#{way}",
			accessKey: accessKey
		) ticketTaker, errorTaker
	###
	Connect account to social service
	###
	connect: (ticket, accessKey) -> (successTaker, errorTaker) ->
		way = 'facebook'
		$log.debug "Connecting to #{way} by token:#{accessKey}"
		http('POST', "account/connect/#{way}",
			ticket: ticket
			accessKey: accessKey
		) successTaker, errorTaker
	###
	Disconnect account to social service
	###
	disconnect: (ticket) -> (successTaker, errorTaker) ->
		way = 'facebook'
		$log.debug "Disconnecting server from #{way}"
		http('POST', "account/disconnect/#{way}",
			ticket: ticket
		) successTaker, errorTaker
	###
	Get start session by server, then pass to taker
	###
	startSession: (ticket, geoinfo) -> (sessionTaker, errorTaker) ->
		$log.debug "Starting session by #{ticket} on #{angular.toJson geoinfo}"
		http('POST', "report/new-session",
			ticket: ticket
			geoinfo: geoinfo
		) sessionTaker, errorTaker
	###
	Put a photo which is encoded by base64 to session
	###
	putPhoto: (session, photos...) -> (successTaker, errorTaker) ->
		$log.debug "Putting a photo with #{session}: #{photos}"
		http('POST', "report/photo",
			session: session
			names: photos
		) successTaker, errorTaker
	###
	Put a photo which is encoded by base64 to session
	###
	inferPhoto: (session) -> (successTaker, errorTaker) ->
		$log.debug "Inferring a photo with #{session}"
		http('POST', "report/infer",
			session: session
		) successTaker, errorTaker
	###
	Put given report to the session
	###
	submitReport: (session, givenReport) -> (success, errorTaker) ->
		report = angular.copy givenReport
		report.dateAt = report.dateAt.getTime()
		$log.debug "Submitting report with #{session}: #{angular.toJson report}"
		http('POST', "report/submit",
			session: session
			report: report
		) success, errorTaker
	###
	Put given report to the session
	###
	publishReport: (ticket, reportId, accessKey) -> (success, errorTaker) ->
		$log.debug "Publishing report(#{reportId}) with #{ticket}: #{accessKey}"
		http('POST', "report/publish/facebook",
			ticket: ticket
			id: reportId
			accessKey: accessKey
		) success, errorTaker
	###
	Load report from server, then pass to taker
	###
	loadReports: (ticket, count, lastId) -> (taker, errorTaker) ->
		$log.debug "Loading #{count} reports from #{lastId}"
		http('POST', "report/load",
			ticket: ticket
			count: count
			last: lastId
		) taker, errorTaker
	###
	###
	readReport: (ticket, id) -> (taker, errorTaker) ->
		$log.debug "Reading report(id:#{id})"
		http('POST', "report/read",
			ticket: ticket
			id: id
		) taker, errorTaker
	###
	Update report to server. ID has to be contain given report.
	###
	updateReport: (ticket, givenReport) -> (success, errorTaker) ->
		report = angular.copy givenReport
		report.dateAt = report.dateAt.getTime()
		$log.debug "Updating report: #{angular.toJson report}"
		http('POST', "report/update",
			ticket: ticket
			report: report
		) success, errorTaker
	###
	Remove report from server
	###
	removeReport: (ticket, id) -> (success, errorTaker) ->
		$log.debug "Removing report(#{id})"
		http('POST', "report/remove",
			ticket: ticket
			id: id
		) success, errorTaker
	###
	Load measures in account settings
	###
	loadMeasures: (ticket) -> (success, errorTaker) ->
		$log.debug "Loading measures"
		http('POST', "account/measures/load",
			ticket: ticket
		) success, errorTaker
	###
	Update measures in account settings
	###
	updateMeasures: (ticket, measures) -> (success, errorTaker) ->
		$log.debug "Changing measures: #{angular.toJson measures}"
		http('POST', "account/measures/update",
			ticket: ticket
			measures: measures
		) success, errorTaker
	###
	Load distributions of own catches
	###
	catchesMine: (ticket) -> (success, errorTaker) ->
		$log.debug "Retrieving my cathces distributions"
		http('POST', "distribution/mine",
			ticket: ticket
		) success, errorTaker
	###
	Load distributions of all catches that includes others
	###
	catchesOthers: (ticket) -> (success, errorTaker) ->
		$log.debug "Retrieving others cathces distributions"
		http('POST', "distribution/others",
			ticket: ticket
		) success, errorTaker
	###
	Load names of catches with it's count
	###
	catchesNames: (ticket) -> (success, errorTaker) ->
		$log.debug "Retrieving names of catches"
		http('POST', "distribution/names",
			ticket: ticket
		) success, errorTaker
	###
	Obtain tide and moon phases
	###
	conditions: (ticket, timestamp, geoinfo) -> (success, errorTaker) ->
		$log.debug "Retrieving conditions: #{timestamp}, #{angular.toJson geoinfo}"
		http('POST', "conditions/get",
			ticket: ticket
			date: timestamp.getTime()
			geoinfo: geoinfo
		) success, errorTaker

.factory 'AcceptanceFactory', ($log, LocalStorageFactory) ->
	store =
		taking: []

	successIt = ->
		LocalStorageFactory.acceptance.save true
		if (list = store.taking)
			store.taking = null
			for suc in list
				suc()

	isReady: LocalStorageFactory.acceptance.load
	obtain: (success) ->
		if @isReady()
			success()
		else
			store.taking.push success
	success: successIt

.factory 'SocialFactory', ($log, LocalStorageFactory) ->
	facebookLogin = (perm...) -> (tokenTaker, errorTaker) -> ionic.Platform.ready ->
		$log.info "Logging in to Facebook: #{perm}"
		facebookConnectPlugin.login perm
		, (result) ->
			$log.debug "Get access: #{angular.toJson result}"
			tokenTaker result.authResponse.accessToken
		, errorTaker
	facebookProfile = (profileTaker, errorTaker) -> ionic.Platform.ready ->
		$log.info "Getting profile of Facebook"
		facebookConnectPlugin.api "me?fields=name", ['public_profile']
		, (info) ->
			$log.debug "Get profile: #{angular.toJson info}"
			profileTaker
				id: info.id
				name: info.name
		, errorTaker
	facebookDisconnect = (onSuccess, errorTaker) -> ionic.Platform.ready ->
		$log.info "Disconnecting from facebook"
		facebookConnectPlugin.api "me/permissions?method=delete", []
		, (info) ->
			$log.debug "Revoked: #{angular.toJson info}"
			facebookConnectPlugin.logout (out) ->
				$log.debug "Logout: #{angular.toJson out}"
				onSuccess()
			, errorTaker
		, errorTaker

	login: (tokenTaker, errorTaker) -> ionic.Platform.ready ->
		facebookConnectPlugin.getLoginStatus (res) ->
			account = LocalStorageFactory.account.load()
			$log.debug "Facebook Login Status for #{angular.toJson account}: #{angular.toJson res}"
			if res.status is "connected" and (account.id is res.authResponse.userID or not account?.id)
			  tokenTaker res.authResponse.accessToken
			else
				facebookLogin('public_profile') tokenTaker, errorTaker
		, (error) ->
			$log.debug "Failed to get Login Status: #{angular.toJson error}"
			facebookLogin('public_profile') tokenTaker, errorTaker
	publish: (tokenTaker, errorTaker) -> ionic.Platform.ready ->
		perm = 'publish_actions'
		facebookConnectPlugin.api "me/permissions", []
		, (res) ->
			$log.debug "Facebook Access Permissions: #{angular.toJson res}"
			pg = res.data.filter (v) -> v.permission is perm and v.status is "granted"
			if (pg.length > 0)
			  facebookConnectPlugin.getAccessToken tokenTaker, errorTaker
			else
			  facebookLogin(perm) tokenTaker, errorTaker
		, errorTaker
	profile: facebookProfile
	disconnect: facebookDisconnect

.factory 'AccountFactory', ($log, $ionicPopup, AcceptanceFactory, LocalStorageFactory, ServerFactory, SocialFactory) ->
	store =
		taking: null
		ticket: null

	stackLogin = (ticketTaker, errorTaker) ->
		if store.ticket then ticketTaker store.ticket
		else
			taker =
				ticket: ticketTaker
				error: errorTaker
			if (list = store.taking)
				list.push taker
				$log.debug "Pushed into queue: #{list}"
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

	withTicket = (ticketProc, successTaker, errorTaker) ->
		$log.debug "Getting ticket for: #{ticketProc}, #{successTaker}"
		auth = ->
			stackLogin (ticket) ->
				ticketProc(ticket) successTaker, (error) ->
					if error.type is ServerFactory.errorTypes.expired
						store.ticket = null
						auth()
					else errorTaker error.msg
			, errorTaker
		auth()

	connect = (tokenTaker, errorTaker) ->
		SocialFactory.login (token) ->
			SocialFactory.profile (profile) ->
				LocalStorageFactory.account.save profile
				$log.info "Social connected."
				tokenTaker token
			, errorTaker
		, errorTaker

	disconnect = (successTaker, errorTaker) ->
		account = LocalStorageFactory.account.load()
		if account?.id
			$log.warn "Social Disconnecting..."
			withTicket (ticket) ->
				ServerFactory.disconnect ticket
			, (result) ->
				SocialFactory.disconnect ->
					LocalStorageFactory.account.remove()
					$log.info "Social disconnected."
					successTaker()
				, errorTaker
			, errorTaker
		else
			errorTaker "Not connected"

	withTicket: withTicket
	connect: (successTaker, errorTaker) ->
		connect (token) ->
			withTicket (ticket) ->
				ServerFactory.connect ticket, token
			, (result) ->
				username = LocalStorageFactory.account.load()?.name
				successTaker username
			, errorTaker
		, errorTaker
	disconnect: (successTaker, errorTaker) ->
		disconnect successTaker, errorTaker
	getUsername: (successTaker, errorTaker) ->
		SocialFactory.profile (profile) ->
			LocalStorageFactory.account.save profile
			successTaker profile.name
		, (error) ->
			$log.error "Failed to get user name: #{error}"
			errorTaker "Not Login"

.factory 'SessionFactory', ($log, $http, $ionicPopup, ServerFactory, SocialFactory, ReportFactory, AccountFactory) ->
	store =
		session: null
		uploadInfo: null

	publish = (reportId) ->
		ReportFactory.publish reportId, ->
			$log.debug "Published session: #{store.session}"
		, (error) ->
			$ionicPopup.alert
				title: 'Error'
				template: "Failed to post"

	submit = (session, report, success, errorTaker) ->
		report.id = ""
		report.userId = ""
		ServerFactory.submitReport(session, report) (reportId) ->
			report.id = reportId
			ReportFactory.add report
			success reportId
		, (error) ->
			$ionicPopup.alert
				title: 'Error'
				template: error.msg
			errorTaker error

	upload = (photo, success, error) ->
		filename = "user-photo"
		$log.info "Posting photo image(#{photo}) by $http with #{angular.toJson store.uploadInfo}"
		data = new FormData()
		for name, value of store.uploadInfo.params
			data.append name, value
		data.append 'file', photo, filename
		$http.post store.uploadInfo.url, data,
			transformRequest: angular.identity,
			headers:
				'Content-Type': undefined
		.success (data, status, headers, config) ->
			$log.debug "Success to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
			success filename
		.error (data, status, headers, config) ->
			$log.debug "Failed to upload: #{status}: #{data}, #{headers}, #{angular.toJson config}"
			error status

	start: (geoinfo, success, errorTaker) ->
		store.session = null
		AccountFactory.withTicket (ticket) ->
			ServerFactory.startSession ticket, geoinfo
		, (result) ->
			store.session = result.session
			store.uploadInfo = result.upload
			success()
		, errorTaker
	putPhoto: (photo, success, inferenceTaker, errorTaker) ->
		if (ses = store.session)
			upload photo, (filename) ->
				ServerFactory.putPhoto(ses, filename) (urls) ->
					ServerFactory.inferPhoto(ses) inferenceTaker, (error) ->
						store.session = null
						errorTaker error.msg
					success urls
				, (error) ->
					store.session = null
					errorTaker error.msg
			, (error) ->
				errorTaker "Failed to upload"
		else errorTaker "No session started"
	finish: (report, isPublish, success, onFinally) ->
		if (session = store.session)
			submit session, report, (reportId) ->
				store.session = null
				$log.info "Session cleared"
				publish(reportId) if isPublish
				success()
				onFinally()
			, onFinally
		else 
			$ionicPopup.alert
				title: 'Error'
				template: "No session started"
			onFinally()
