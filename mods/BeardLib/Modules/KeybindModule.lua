KeybindModule = KeybindModule or class(ModuleBase)

KeybindModule.type_name = "Keybind"

function KeybindModule:init(core_mod, config)
    if not self.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function KeybindModule:Load()
    LuaModManager:AddJsonKeybinding( self._config, self._mod.ModPath )
end

BeardLib:RegisterModule(KeybindModule.type_name, KeybindModule)
