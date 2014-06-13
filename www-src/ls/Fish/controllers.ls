.controller 'MenuCtrl', ($log, $scope) !->
	$scope.openMap = !-> alert "Open Map"

.controller 'AcceptanceCtrl', ($log, $scope, AcceptanceFactory) !->
	$scope.terms = AcceptanceFactory.terms-of-use!

.controller 'ShowRecordsCtrl', ($log, $scope, $ionicModal, $ionicPopup, RecordFactory, GMapFactory) !->
	$ionicModal.fromTemplateUrl 'template/show-record.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.showMap = !->
		GMapFactory.showMap $scope.record.location.latLng

	$scope.refreshRecords = !->
		$scope.records = RecordFactory.load!
	$scope.$on 'fathens-records-changed', (event, args) !->
		$scope.refreshRecords!

	$scope.detail = (index) !->
		$scope.index = index
		$scope.record = $scope.records[index]
		$scope.modal.show!

	$scope.delete = (index) !->
		$ionicPopup.confirm {
			title: "Delete Record"
			template: "Are you sure to delete this record ?"
		}
		.then (res) !-> if res
			RecordFactory.remove index
			$scope.$broadcast 'fathens-records-changed'
			$scope.modal.hide!

	$scope.close = !-> $scope.modal.hide!

.controller 'EditRecordCtrl', ($log, $scope, $rootScope, $ionicModal, RecordFactory, GMapFactory) !->
	# $scope.record = 表示中のレコード
	# $scope.index = 表示中のレコードの index
	$ionicModal.fromTemplateUrl 'template/edit-record.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.title = "Edit Record"

	$scope.showMap = !->
		GMapFactory.showMap $scope.record.location.latLng ,(latLng) !->
			$scope.record.location.latLng = latLng

	$scope.edit = !->
		$scope.currentRecord = angular.copy $scope.record
		$scope.modal.show!

	$scope.cancel = !->
		angular.copy $scope.currentRecord, $scope.record
		$scope.modal.hide!
	
	$scope.submit = !->
		$scope.currentRecord = null
		RecordFactory.update $scope.index, $scope.record
		$rootScope.$broadcast 'fathens-records-changed'
		$scope.modal.hide!

.controller 'AddRecordCtrl', ($log, $scope, $rootScope, $ionicModal, $ionicPopup, PhotoFactory, RecordFactory, GMapFactory, SessionFactory, LocalStorageFactory) !->
	$ionicModal.fromTemplateUrl 'template/edit-record.html'
		, (modal) !-> $scope.modal = modal
		,
			scope: $scope
			animation: 'slide-in-up'

	$scope.title = "New Record"
	$scope.publish =
		do: {}
		ables: [LocalStorageFactory.login-way.load!]

	newRecord = (uri) ->
		photo: uri
		dateAt: new Date!
		location:
			name: "Here"
			latLng: null
		fishes: []
		comment: ""

	$scope.open = !->
		$log.info "Opening modal..."
		SessionFactory.start!
		PhotoFactory.select (uri) !->
			$scope.$apply $scope.record = newRecord uri
			$scope.modal.show!
		, (msg) !->
			$ionicPopup.alert {
				title: "No photo selected"
				subTitle: "Need a photo to record"
			}

	$scope.showMap = !->
		GMapFactory.showMap $scope.record.location.latLng ,(latLng) !->
			$scope.record.location.latLng = latLng

	$scope.cancel = !-> $scope.modal.hide!
	$scope.submit = !->
		record = $scope.record
		RecordFactory.add angular.copy(record)
		$rootScope.$broadcast 'fathens-records-changed'
		SessionFactory.finish record, [name for name, value of $scope.publish.do when value]
		$scope.modal.hide!

.controller 'AddFishCtrl', ($scope, $ionicPopup) !->
	# $scope.record.fishes
	$scope.deleteFish = (index) !-> $scope.record.fishes.splice index, 1
	$scope.addFish = !->
		$scope.fish = {
			name: null
			count: 1
			units:
				length: 'cm'
				weight: 'kg'
		}
		$ionicPopup.show {
			title: 'Add Fish'
			templateUrl: "add-fish"
			scope: $scope
			buttons:
				*text: "Cancel"
					type: "button-default"
					onTap: (e) -> null
				*text: "OK"
					type: "button-positive"
					onTap: (e) !->
						if $scope.fish.name
						then return $scope.fish
						else e.preventDefault!
		}
		.then (res) !-> $scope.record.fishes.push res if res
			, (err) !-> alert "Error: #err"
			, (msg) !-> alert "Message: #msg"
