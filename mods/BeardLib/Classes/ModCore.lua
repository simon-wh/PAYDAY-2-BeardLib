core:import("CoreSerialize")

ModCore = ModCore or class()
ModCore._ignored_modules = {}
function ModCore:init(config_path, load_modules, post_init)
    if not io.file_is_readable(config_path) then
        self:log("[ERROR] Config file is not readable!")
        return
    end
    self._auto_post_init = post_init
    self.ModPath = ModPath
    self.SavePath = SavePath

    self:LoadConfigFile(config_path)
    if load_modules then
        self:init_modules()
    end
end

function ModCore:post_init(ignored_modules)
    for _, module in pairs(self._modules) do
        if (not ignored_modules or not table.contains(ignored_modules, module._name)) then
            local success, err = pcall(function() module:post_init() end)

            if not success then
                self:log("[ERROR] An error occured on the post initialization of %s. Error:\n%s", module._name, tostring(err))
            end
        end
    end
end

function ModCore:LoadConfigFile(path)
    local file = io.open(path, "r")
    local config = ScriptSerializer:from_custom_xml(file:read("*all"))

    self.Name = config.name or "ERR:" .. tostring(table.remove(string.split(self.ModPath, "/")))
    if config.global_key then
        self.global = config.global_key
        if not _G[self.global] then
            rawset( _G, self.global, self)
        end
    end

    self._clean_config = deep_clone(config)
    self._config = config
end

function ModCore:init_modules()
    if self.modules_initialized then
        return
    end

    self._modules = {}
    for i, module_tbl in ipairs(self._config) do
        if type(module_tbl) == "table" then
            if not table.contains(self._ignored_modules, module_tbl._meta) then
                local node_class = BeardLib.modules[module_tbl._meta]

                if not node_class and module_tbl._force_search then
                    node_class = CoreSerialize.string_to_classtable(module_tbl._meta)
                end

                if node_class then
                    local success, node_obj, valid = pcall(function() return node_class:new(self, module_tbl) end)
                    if success then
                        if valid == false then
                            self:log("Module with name %s does not contain a valid config. See above for details", node_obj._name)
                        else
                            if not node_obj._loose or node_obj._name ~= node_obj.type_name then
                                if self[node_obj._name] then
                                    self:log("The name of module: %s already exists in the mod table, please make sure this is a unique name!", node_obj._name)
                                end

                                self[node_obj._name] = node_obj
                            end
                            table.insert(self._modules, node_obj)
                        end
                    else
                        self:log("[ERROR] An error occured on initilization of module: %s. Error:\n%s", module_tbl._meta, tostring(node_obj))
                    end
                elseif not self._config.ignore_errors then
                    self:log("[ERROR] Unable to find module with key %s", module_tbl._meta)
                end
            end
        end
    end

    if self._auto_post_init or self._config.post_init then
        self:post_init()
    end
    self.modules_initialized = true
end

function ModCore:GetRealFilePath(path, lookup_tbl)
    if string.find(path, "%$") then
        return string.gsub(path, "%$(%w+)%$", lookup_tbl or self)
    else
        return path
    end
end

function ModCore:log(str, ...)
    log("[" .. self.Name .. "] " .. string.format(str, ...))
end

function ModCore:StringToTable(str)
    if str == "self" then return self end

    if (string.find(str, "$")) then
        str = string.gsub(str, "%$(%w+)%$", self)
    end

    local global_tbl
    local self_search = "self."
    if string.begins(str, self_search) then
        str = string.sub(str, #self_search + 1, #str)
        global_tbl = self
    end

    return BeardLib.Utils:StringToTable(str, global_tbl)
end

function ModCore:StringToCallback(str, self_tbl)
    local split = string.split(str, ":")

    local func_name = table.remove(split)

    local global_tbl_name = split[1]

    local global_tbl = self:StringToTable(global_tbl_name)
    if global_tbl then
        return callback(self_tbl or global_tbl, global_tbl, func_name)
    else
        return nil
    end
end

function ModCore:GetPath()
    return self.ModPath
end