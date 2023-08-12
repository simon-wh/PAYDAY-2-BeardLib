MenuModule = MenuModule or BeardLib:ModuleClass("Menu", ModuleBase)
function MenuModule:Load()
	local path = "<MenuModule>"
	local data = self._config
	if not data.name then
		self:LogF(LogLevel.ERROR, "Load", "Creation of menu at path '%s' has failed, no menu name given.", path)
		return
	end
	RaidMenuHelper:ConvertXMLData(data)
	RaidMenuHelper:LoadMenu(data, path, self._mod)
end