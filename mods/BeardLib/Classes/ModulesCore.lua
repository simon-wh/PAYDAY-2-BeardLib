BeardLib.ModCore = BeardLib.ModCore or class()

function BeardLib.ModCore:init(config_path)
    if not io.file_is_readable(config_path) then
        BeardLib:log("[ERROR] Config file is not readable!")
    end
    
    self.ModPath = ModPath
    self.SavePath = SavePath
    
    self:LoadConfigFile(path)
end

function BeardLib.ModCore:LoadConfigFile(path)
    local file = io.open(path, "r")
    local config = ScriptSerializer:from_custom_xml(file:read("*all"))
    
    self.Name = config.name
    self.GlobalKey = config.global_key
    
    if config.modules then
        for i = 1, table.maxn(config.modules) do
            local module_tbl = config.modules[i]
            
            local node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
            
            if node_class then
                self[module_tbl.name or node_class.type_name] = node_class:new(self, module_tbl)
            end
        end
    end
end

function BeardLib.ModCore:GetRealFilePath(path)
    if string.find(path, "%$") then
        return string.gsub(path, "%$(%w+)%$", self)
    else
        return path
    end
end