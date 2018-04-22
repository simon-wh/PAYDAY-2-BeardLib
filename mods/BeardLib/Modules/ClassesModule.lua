ClassesModule = ClassesModule or class(ModuleBase)
ClassesModule.type_name = "Classes"

function ClassesModule:init(core_mod, config)
    if not ClassesModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()
    return true
end

function ClassesModule:Load(config, prev_dir)
	config = config or self._config
	
    local dir = self:GetPath(config.directory, prev_dir)
    for _, c in ipairs(config) do
        if c._meta == "class" then
            local class_file = Path:Combine(dir, c.file)
            if FileIO:Exists(class_file) then
                dofile(class_file)
            else
                BeardLib:log("[ERROR] Class file not readable by the lua state! File: %s", class_file)
            end
        elseif c._meta == "classes" then
            self:Load(c, dir)
        end
    end
end

BeardLib:RegisterModule(ClassesModule.type_name, ClassesModule)