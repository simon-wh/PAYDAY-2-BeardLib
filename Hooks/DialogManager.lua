Hooks:PostHook(DialogManager, "_play_dialog", "BeardLibDialogManagerPlayDialog", function (self)
	if self._current_dialog.unit == self._bain_unit and managers.music._xa_source then
		managers.music._xa_source:set_volume(managers.music._xa_volume * 0.5)
	end
end)

Hooks:PostHook(DialogManager, "_stop_dialog", "BeardLibDialogManagerStopDialog", function ()
	if managers.music._xa_source then
		managers.music._xa_source:set_volume(managers.music._xa_volume)
	end
end)
