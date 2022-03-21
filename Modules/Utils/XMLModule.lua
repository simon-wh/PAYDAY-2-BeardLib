XMLModule = XMLModule or BeardLib:ModuleClass("XML", ModuleBase)
XMLModule.required_params = {"path"}
XMLModule._loose = true

local load_first = {Hooks = true, Classes = true}

function XMLModule:Load()
    local file_path = self._mod:GetRealFilePath(Path:Combine(self._mod.ModPath, self._config.path))
    self._loaded_config = FileIO:ReadScriptData(file_path, self._config.file_type or "custom_xml", self._config.clean_file)

    local order = self._loaded_config.load_first or load_first

	table.sort(self._loaded_config, function(a,b)
		local a_ok = type(a) == "table" and order[a._meta] or false
		local b_ok = type(b) == "table" and order[b._meta] or false
		return (a_ok and not b_ok) or (a.priority or 1) > (b.priority or 1)
	end)

    if self._loaded_config then
        for _, module_tbl in ipairs(self._loaded_config) do
            self._mod:AddModule(module_tbl)
        end
    end
end