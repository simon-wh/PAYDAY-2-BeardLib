for _, Name in pairs(BeardLib.custom_mission_elements) do
    dofile(BeardLib.config.classes_dir .. "Elements/Element" .. Name .. ".lua")
end

local MissionManager_add_script = MissionManager._add_script
function MissionManager:_add_script(data, ...)
    if self._scripts[data.name] then
        return
    end
    MissionManager_add_script(self, data, ...)
end