AddFramework = AddFramework or BeardLib:Class(FrameworkBase)
AddFramework.add_file = "add.xml"
AddFramework.type_name = "Add"
AddFramework._directory = BeardLib.config.mod_override_dir
AddFramework.menu_color = Color(0, 0.25, 1)
AddFramework.add_configs = {}

function AddFramework:init()
    -- Deprecated, try not to use.
    if self.type_name == AddFramework.type_name then
        BeardLib.Frameworks.add = self
        BeardLib.managers.AddFramework = self
    end

    AddFramework.super.init(self)
end

function AddFramework:FindMods()
	Hooks:Call("BeardLibFrameworksFindMods", self)

    local dirs = FileIO:GetFolders(self._directory)
    if dirs then
        for _, dir in pairs(dirs) do
			Hooks:Call("BeardLibFrameworksFoldersLoop", self, dir)
            local p = path:CombineDir(self._directory, dir)
            local main_file = path:Combine(p, self.main_file_name)
            local add_file = path:Combine(p, self.add_file)
            if FileIO:Exists(main_file) then
                self:LoadMod(dir, p, main_file)
            elseif not self._ignore_detection_errors then
                BeardLib:Err("Could not read %s", main_file)
            end
			if FileIO:Exists(add_file) then
                local file = io.open(add_file, "r")
                local config = ScriptSerializer:from_custom_xml(file:read("*all"))
                local directory = config.full_directory or Path:Combine(p, config.directory)
                BeardLib.Managers.Package:LoadConfig(directory, config)
                self.add_configs[p] = config
            end
        end
    end
end