function ConnectionNetworkHandler:sync_stage_settings_ignore_once(...)
	self:sync_stage_settings(...)
	self._ignore_stage_settings_once = true
end

local orig_sync_stage_settings = ConnectionNetworkHandler.sync_stage_settings
function ConnectionNetworkHandler:sync_stage_settings(level_id_index, ...)
	if self._ignore_stage_settings_once then
		self._ignore_stage_settings_once = nil
		return
	end
	return orig_sync_stage_settings(self, level_id_index, ...)
end

function ConnectionNetworkHandler:lobby_sync_update_level_id_ignore_once(...)
	self:lobby_sync_update_level_id(...)
	self._ignore_update_level_id_once = true
end

local orig_lobby_sync_update_level_id = ConnectionNetworkHandler.lobby_sync_update_level_id
function ConnectionNetworkHandler:lobby_sync_update_level_id(level_id_index, ...)
	if self._ignore_update_level_id_once then
		self._ignore_update_level_id_once = nil
		return
	end
	return orig_lobby_sync_update_level_id(self, level_id_index, ...)
end