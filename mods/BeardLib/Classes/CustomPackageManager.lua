_G.CustomPackageManager = {}
Global.cmp = Global.cmp or {}
Global.cmp.custom_loaded_packages = Global.cmp.custom_loaded_packages or {}
local cmp = CustomPackageManager
cmp.custom_packages = {}

function cmp:RegisterPackage(id, directory, config)
    local func_name = "CustomPackageManager:RegisterPackage"
    if (not BeardLib.Utils:CheckParamsValidty({id, directory, config},
        {
            func_name = func_name,
            params = {
                { type="string", allow_nil = false },
                { type="string", allow_nil = false },
                { type="table", allow_nil = false }
            }
        })) then
        return false
    end
    id = id:key()
    if self.custom_packages[id] then
        BeardLib:log("[ERROR] Package with ID '%s' already exists! Returning...", id)
        return false
    end

    self.custom_packages[id] = {dir = directory, config = config}

    return true
end

function cmp:LoadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:LoadPackageConfig(pck.dir, pck.config)
        Global.cmp.custom_loaded_packages[id] = true
        return true
    end
end

function cmp:UnLoadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:UnloadPackageConfig(pck.config)
        Global.cmp.custom_loaded_packages[id] = false
        return false
    end
end

function cmp:PackageLoaded(id)
    return Global.cmp.custom_loaded_packages[id:key()]
end

function cmp:HasPackage(id)
    return not not self.custom_packages[id:key()]
end

function cmp:LoadPackageConfig(directory, config)
    if not SystemFS then
        BeardLib:log("[ERROR] SystemFS does not exist! Custom Packages cannot function without this! Do you have an outdated game version?")
        return
    end
    local loading = {}
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = BeardLib.Utils.Path:Normalize(path)
                local ids_ext = Idstring(typ)
                local ids_path = Idstring(path)
                local file_path = BeardLib.Utils.Path:Combine(directory, path) ..".".. typ
                if SystemFS:exists(file_path) then
                    if (not DB:has(ids_ext, ids_path) or child.force) then
                        --self:log("Added file %s %s", path, typ)
                        FileManager:AddFile(ids_ext, ids_path, file_path)
                        if child.reload then
                            PackageManager:reload(ids_ext, ids_path)
                        end
                        if child.load then
                            table.insert(loading, {ids_ext, ids_path})
                            --FileManager:LoadAsset(ids_ext, ids_path)
                        end
                    end
                else
                    BeardLib:log("[ERROR] File does not exist! %s", file_path)
                end
            else
                BeardLib:log("[ERROR] Node in %s does not contain a definition for both type and path", add_file_path)
            end
        end
    end
    --For some reason this needs to be here, instead of loading in the main loop or the game will go into a hissy fit 
    for _, file in pairs(loading) do
        local ids_ext, ids_path = unpack(file)
        FileManager:LoadAsset(ids_ext, ids_path)
    end
end


function cmp:UnloadPackageConfig(config)
    BeardLib:log("Unloading added files")
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = BeardLib.Utils.Path:Normalize(path)
                local ids_ext = Idstring(typ)
                local ids_path = Idstring(path)
                if DB:has(ids_ext, ids_path) then
                    if child.unload ~= false then
                        FileManager:UnLoadAsset(ids_ext, ids_path)
                    end
                    --self:log("Unloaded %s %s", path, typ)
                    FileManager:RemoveFile(ids_ext, ids_path)
                end
            else
                BeardLib:log("[ERROR] Node in %s does not contain a definition for both type and path", add_file_path)
            end
        end
    end
end