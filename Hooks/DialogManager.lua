Hooks:PostHook(DialogManager, "_play_dialog", "BeardLibDialogManagerPlayDialog", function (self)
	managers.music:set_volume_multiplier(0.5)
end)

Hooks:PostHook(DialogManager, "_stop_dialog", "BeardLibDialogManagerStopDialog", function ()
	managers.music:set_volume_multiplier(1, 1)
end)
