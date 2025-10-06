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

    local mod = BeardLib.current_level._mod
    local file = self._values.file
    local use_path = self._values.use_path
    local argument = self._values.argument

    if not string.is_nil_or_empty(file) then
        local path
        if use_path == "mod" then
            path = Path:Combine(mod.ModPath, file)
        elseif use_path == "level" then
            path = Path:Combine(mod.ModPath, BeardLib.current_level._inner_dir, file)
        elseif use_path == "full" then
            path = file
        end

        if path and FileIO:Exists(path) then
            local ran, ret = pcall(function()
                local func = blt.vm.dofile(path)
                if func then
                    if func(instigator, mod, argument) ~= false then
                        return true
                    end
                    return false
                else
                    error("The file must return a function to execute!")
                end
            end)
            if ran and ret then
                ElementExecuteWithCode.super.on_executed(self, instigator)
            end
        else
            self:error("File '%s' doesn't exist", path)
        end
    else
        self:error("No file was defined")
    end
end

function ElementExecuteCode:error(s, ...)
    local mod = BeardLib.current_level._mod
    mod:LogErr('[ElementExecuteCode ID %s Name %s] ' .. s, tostring(self._id), tostring(self._editor_name), ...)
end

function ElementExecuteCode:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementExecuteCode:load(data)
    self:set_enabled(data.enabled)
end