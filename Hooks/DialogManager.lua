-- This file includes dynamic music volume multipliers for contractor voice lines

Hooks:PostHook(DialogManager, "_play_dialog", "BeardLibDialogManagerPlayDialog", function (self)
	managers.music:set_volume_multiplier("dialog", 0.5)
end)

Hooks:PostHook(DialogManager, "_stop_dialog", "BeardLibDialogManagerStopDialog", function (self)
	managers.music:set_volume_multiplier("dialog", 1, 1)
end)
