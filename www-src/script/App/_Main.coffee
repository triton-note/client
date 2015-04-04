angular.module('triton_note', ['ionic', 'monospaced.elastic', 'triton_note.config', 'triton_note.controllers', 'triton_note.device', 'triton_note.directive', 'triton_note.filter', 'triton_note.reports', 'triton_note.server'])
.run ($log, GMapFactory) ->
	ionic.Platform.ready ->
		$log.info "Device is ready"
		StatusBar.hide()
		ionic.Platform.fullScreen()
