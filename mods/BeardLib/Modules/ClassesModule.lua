ClassesModule = ClassesModule or class(ModuleBase)
ClassesModule.type_name = "Classes"

function ClassesModule:init(core_mod, config)
    if not ClassesModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()
    return true
end

function ClassesModule:Load(config)
    local path = self:GetPath(config and config.directory or "")
    config = config or self._config
    for _, c in ipairs(config) do
        if c._meta == "class" then
            local class_file = BeardLib.Utils.Path:Combine(path, c.file)
            if FileIO:Exists(class_file) then
                dofile(class_file)
            else
                BeardLib:log("[ERROR] Class file not readable by the lua state! File: %s", class_file)
            end
        elseif c._meta == "classes" then
            self:Load(c)
        end
    end
end

function ClassesModule:GetPath(additional)
    return BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory, additional or "")
end

BeardLib:RegisterModule(ClassesModule.type_name, ClassesModule)