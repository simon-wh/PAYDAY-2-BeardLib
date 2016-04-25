core:import("CoreSerialize")

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
        self._modules = config.modules
    end
end

function ModCore:init_modules()
    if self._modules then
        for i, module_tbl in ipairs(self._modules) do
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

function ModCore:StringToTable(str)
    if (string.find(str, "$")) then
        str = string.gsub(str, "%$(%w+)%$", { ["global"] = self.GlobalKey })
    end
    
    return BeardLib.Utils:StringToTable(str)
end

function ModCore:StringToCallback(str)
    local split = string.split(str, ":")
    
    local func_name = table.remove(split)
    
    local global_tbl_name = split[1]
   
    local global_tbl = self:StringToTable(global_tbl_name)
    
    if global_tbl then
        return callback(global_tbl, global_tbl, func_name)
    else
        return nil
    end
end