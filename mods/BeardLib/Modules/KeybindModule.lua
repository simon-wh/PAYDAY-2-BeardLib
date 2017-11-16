KeybindModule = KeybindModule or class(ModuleBase)

KeybindModule.type_name = "Keybind"

function KeybindModule:init(core_mod, config)
    if not KeybindModule.super.init(self, core_mod, config) then
        return false
    end

    self:Load()

    return true
end

function KeybindModule:Load()
	if not self._config.keybind_id then 
		self:log("[ERROR] Keybind does not contain a definition for keybind_id!")
		return
	end
	self._config.run_in_menu = self._config.run_in_menu or true
	self._config.run_in_game = self._config.run_in_game or true
	if BLT and BLT.Keybinds then
		BLT.Keybinds:register_keybind(self._mod, self._config)
	else
		LuaModManager:AddJsonKeybinding(self._config, self._mod.ModPath .. "/")		
	end
end

BeardLib:RegisterModule(KeybindModule.type_name, KeybindModule)