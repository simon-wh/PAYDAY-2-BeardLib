FrameworkBase = FrameworkBase or class()
FrameworkBase._directory = ""
FrameworkBase.auto_init_modules = true
FrameworkBase.main_file_name = "main.xml"
FrameworkBase._mod_core = ModCore
function FrameworkBase:init()
    self._loaded_mods = {}
    self:Load()
end

function FrameworkBase:LoadMod(dir, path, main_file)
	declare("ModPath", path)
	local success, node_obj = pcall(function() return self._mod_core:new(main_file, self.auto_init_modules) end)
	if success then
		BeardLib:log("Loaded Config: %s", path)
		self._loaded_mods[dir] = node_obj
	else
		BeardLib:log("[ERROR] An error occured on initilization of Mod %s. Error:\n%s", dir, tostring(node_obj))
	end
end

function FrameworkBase:Load()
    local dirs = file.GetDirectories(self._directory)
    if dirs then
        for _, dir in pairs(dirs) do
            local p = path:Combine(self._directory, dir)
            local main_file = path:Combine(p, self.main_file_name)
            if FileIO:Exists(main_file) then
                if not self._loaded_mods[dir] then
                    self:LoadMod(dir, p, main_file)
                end
            elseif not self._ignore_detection_errors then
                BeardLib:log("[ERROR] Could not read %s", main_file)
            end
        end
    end
end