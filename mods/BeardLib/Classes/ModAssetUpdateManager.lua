ModAssetUpdateManager = ModAssetUpdateManager or class()
ModAssetUpdateManager.save_path = SavePath .. "mod_assets_manager.txt"
ModAssetUpdateManager._registered_updates = {}
ModAssetUpdateManager._ready_for_update = true
function ModAssetUpdateManager:init()
    self._data = {}
    self:load_manager_file()
end

function ModAssetUpdateManager:CheckUpdateStatus(mod_id)
    if self._data[mod_id] ~= nil then
        return self._data[mod_id]
    else
        return true
    end
end

function ModAssetUpdateManager:SetUpdateStatus(mod_id, status)
    self._data[mod_id] = status
    self:save_manager_file()
end

function ModAssetUpdateManager:save_manager_file()
    local file = io.open(self.save_path, "w+")
    local data_str = json.encode(self._data)
	file:write(data_str == "[]" and "{}" or data_str)
	file:close()
end

function ModAssetUpdateManager:load_manager_file()
    local file = io.open(self.save_path, 'r')
    if file then
        local ret, data = pcall(function() return json.decode(file:read("*all")) end)
        if ret then
            self._data = data
        end
    end
end

function ModAssetUpdateManager:RegisterUpdate(func)
    table.insert(self._registered_updates, func)
end

function ModAssetUpdateManager:update(t, dt)
    if self._ready_for_update and next(self._registered_updates) then
        self._ready_for_update = false
        table.remove(self._registered_updates, 1)()
    end
end

return ModAssetUpdateManager
