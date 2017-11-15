AddFramework = AddFramework or class(FrameworkBase)
AddFramework._ignore_detection_errors = true
AddFramework.add_file = "add.xml"
function AddFramework:init()
    self._directory = BeardLib.config.mod_override_dir
    AddFramework.super.init(self)
end

function AddFramework:RegisterHooks()
    table.sort(self._loaded_mods, function(a,b)
        return a.Priority < b.Priority
    end)
    for _, mod in pairs(self._loaded_mods) do
        if not mod._disabled then
            for _, module in pairs(mod._modules) do
                if module.RegisterHook then
                    local success, err = pcall(function() module:RegisterHook() end)

                    if not success then
                        BeardLib:log("[ERROR] An error occured on the hook registration of %s. Error:\n%s", module._name, tostring(err))
                    end
                end
            end
        end
    end
end

function AddFramework:Load()
    local dirs = FileIO:GetFolders(self._directory)
    if dirs then
        for _, dir in pairs(dirs) do
            local p = path:Combine(self._directory, dir)
            local main_file = path:Combine(p, self.main_file_name)
            local add_file = path:Combine(p, self.add_file)
            if FileIO:Exists(main_file) then
                self:LoadMod(dir, p, main_file)
            elseif not self._ignore_detection_errors then
                BeardLib:log("[ERROR] Could not read %s", main_file)
            end
			if FileIO:Exists(add_file) then
				local file = io.open(add_file, "r")
                AddFilesModule.Load({_mod = {ModPath = p}, _config = ScriptSerializer:from_custom_xml(file:read("*all"))})
            end
        end
    end
end

return AddFramework
