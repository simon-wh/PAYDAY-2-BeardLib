ModuleBase = ModuleBase or class()

ModuleBase.type_name = "ModuleBase"

function ModuleBase:init(core_mod, config)
    self._mod = core_mod
    self._name = config.name or self.type_name
    if config.file ~= nil then
        local file = io.open(self._mod:GetRealFilePath(config.file), "r")
        self._config = ScriptSerializer:from_custom_xml(file:read("*all"))
    else
        self._config = config
    end
end

function ModuleBase:post_init()
    if self._post_init_complete then
        return false
    end

    if self._config.post_init_clbk then
        local clbk = self._mod:StringToCallback(self._config.post_init_clbk)
        if clbk then
            clbk()
        end
    end

    self._post_init_complete = true
    return true
end
