ModCore = ModCore or class()

function ModCore:init(config_path)
    if not io.file_is_readable(config_path) then
        BeardLib:log("[ERROR] Config file is not readable!")
    end
    
    self.ModPath = ModPath
    self.SavePath = SavePath
    
    self:LoadConfigFile(config_path)
end

function ModCore:LoadConfigFile(path)
    local file = io.open(path, "r")
    local config = ScriptSerializer:from_custom_xml(file:read("*all"))
    
    self.Name = config.name
    self.GlobalKey = config.global_key
    
    if config.modules then
        for i, module_tbl in ipairs(config.modules) do
            local node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
            
            if node_class then
                self[module_tbl.name or node_class.type_name] = node_class:new(self, module_tbl)
            end
        end
    end
end

function ModCore:GetRealFilePath(path)
    if string.find(path, "%$") then
        return string.gsub(path, "%$(%w+)%$", self)
    else
        return path
    end
end

function ModCore:log(str)
    log("[" .. self.Name .. "] " .. str)
end