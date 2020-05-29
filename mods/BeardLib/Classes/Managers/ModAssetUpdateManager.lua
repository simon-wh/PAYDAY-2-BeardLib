ModAssetUpdateManager = ModAssetUpdateManager or BeardLib:ManagerClass("Update")

function ModAssetUpdateManager:init()
    self._registered_updates = {}
    self._ready_for_update = {}
    self._data = {}

    -- Deprecated, try not to use.
    BeardLib.managers.asset_update = self
end

function ModAssetUpdateManager:UpdatesIgnored(mod)
    return mod:GetSetting("IgnoreUpdates") == true
end

function ModAssetUpdateManager:RegisterUpdate(func)
    table.insert(self._registered_updates, func)
end

function ModAssetUpdateManager:IsReadyForUpdate()
    return self._ready_for_update
end

function ModAssetUpdateManager:PrepareForUpdate()
    self._ready_for_update = true
end

function ModAssetUpdateManager:Update(t, dt)
    if self._ready_for_update and next(self._registered_updates) then
        self._ready_for_update = false
        table.remove(self._registered_updates, 1)()
    end
end

--Unused
ModAssetUpdateManager.SetUpdatesIgnored = Deprected
ModAssetUpdateManager.CheckUpdateStatus = Deprected
ModAssetUpdateManager.SetUpdateStatus = Deprected
ModAssetUpdateManager.save_manager_file = Deprected
ModAssetUpdateManager.load_manager_file = Deprected