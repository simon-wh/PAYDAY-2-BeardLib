AddFramework = AddFramework or class(FrameworkBase)
local Framework = AddFramework
Framework._ignore_detection_errors = true
Framework.add_file = "add.xml"
Framework.type_name = "add"
Framework._directory = BeardLib.config.mod_override_dir

function Framework:Load()
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

BeardLib:RegisterFramework(Framework.type_name, Framework)
return Framework