KeybindModule = KeybindModule or BeardLib:ModuleClass("Keybind", ModuleBase)

function KeybindModule:Load()
	if not self._config.keybind_id and not self._config.id then
		self:Err("Keybind does not contain a definition for keybind_id!")
		return
	end

	self._config.keybind_id = self._config.keybind_id or self._config.id
	local config = table.merge({run_in_menu = true, run_in_game = true}, self._config)

	if BLT and BLT.Keybinds then
		BLT.Keybinds:register_keybind_json(self._mod, config)
	else
		LuaModManager:AddJsonKeybinding(config, self._mod.ModPath .. "/")
	end
end