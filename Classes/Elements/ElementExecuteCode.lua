core:import("CoreMissionScriptElement")
ElementExecuteCode = ElementExecuteCode or class(CoreMissionScriptElement.MissionScriptElement)

function ElementExecuteCode:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end

function ElementExecuteCode:client_on_executed(...)
    self:on_executed(...)
end

function ElementExecuteCode:on_executed(instigator)
    if not self._values.enabled then
        return
    end

    local mod = BeardLib.current_level.mod
    local file = self._values.file
    if file then
        local path = Path:Combine(mod.ModPath, file)
        if FileIO:Exists(path) then
            local ret = pcall(function()
                local func = blt.vm.dofile(Path:Combine(mod.ModPath, file))
                if func then
                    if func(instigator) then
                        return true
                    end
                else
                    self:error("The file must return a function to execute!")
                    return
                end
            end)
            if ret then
                ElementExecuteWithCode.super.on_executed(self, instigator)
            else
                self:error("An error has occurred while executing the element's code")
            end
        else
            self:error("File doesn't exist")
        end
    else
        self:error("No file was defined")
    end
end

function ElementExecuteCode:error(s, ...)
    local mod = BeardLib.current_level.mod
    mod:LogErr('[ElementExecuteCode ID %s Name %s]', tostring(self._values.id), tostring(self._values.editor_name), ...)
end

function ElementExecuteCode:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementExecuteCode:load(data)
    self:set_enabled(data.enabled)
end