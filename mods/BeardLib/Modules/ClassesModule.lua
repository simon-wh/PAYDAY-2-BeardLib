ClassesModule = ClassesModule or class(ModuleBase)

ClassesModule.type_name = "Classes"

function ClassesModule:init(core_mod, config)
    if not ClassesModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()
    return true
end

function ClassesModule:Load()
    local path = BeardLib.Utils.Path:Combine(self._mod.ModPath, self._config.directory)
    for _, c in ipairs(self._config) do
        if c._meta == "class" then
            local class_file = BeardLib.Utils.Path:Combine(path, c.file)
            if FileIO:Exists(class_file) then
                dofile(class_file)
            else
                BeardLib:log("[ERROR] Class file not readable by the lua state! File: %s", class_file)
            end
        end
    end
end

BeardLib:RegisterModule(ClassesModule.type_name, ClassesModule)