ModuleBase = ModuleBase or class()

ModuleBase.type_name = "ModuleBase"

function ModuleBase:init(core_mod, config)
    self._mod = core_mod
    if config.file ~= nil then
        local file = io.open(self._mod:GetRealFilePath(config.file), "r")
        self._config = ScriptSerializer:from_custom_xml(file:read("*all"))
    else
        self._config = config
    end
end