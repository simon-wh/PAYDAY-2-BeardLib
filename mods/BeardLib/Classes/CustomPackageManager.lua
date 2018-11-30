Global.cmp = Global.cmp or {}
Global.cmp.custom_loaded_packages = Global.cmp.custom_loaded_packages or {}
CustomPackageManager = CustomPackageManager or {}

local C = CustomPackageManager
C.custom_packages = {}
C.unload_on_restart = {}
C.ext_convert = {dds = "texture", png = "texture", tga = "texture", jpg = "texture", bik = "movie"}

function C:RegisterPackage(id, directory, config)
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
    local id_key = id:key()
    if self.custom_packages[id_key] then
        BeardLib:log("[ERROR] Package with ID '%s' already exists! Returning...", id)
        return false
    end

    self.custom_packages[id_key] = {dir = directory, config = config, id = id}

    return true
end

function C:LoadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:LoadPackageConfig(pck.dir, pck.config)
        Global.cmp.custom_loaded_packages[id] = true
        return true
    end
end

function C:UnLoadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:UnloadPackageConfig(pck.config)
        Global.cmp.custom_loaded_packages[id] = false
        return false
    end
end

function C:PackageLoaded(id)
    return Global.cmp.custom_loaded_packages[id:key()]
end

function C:HasPackage(id)
    return not not self.custom_packages[id:key()]
end

local UNIT_LOAD = "unit_load"
local ADD = "add"

local UNIT = "unit"
local MODEL = "model"
local OBJECT = "object"
local TEXTURE = "texture"
local MAT_CONFIG = "material_config"
local SEQ_MANAGER = "sequence_manager"
local COOKED_PHYSICS = "cooked_physics"

local UNIT_IDS = UNIT:id()
local MODEL_IDS = MODEL:id()
local OBJECT_IDS = OBJECT:id()
local TEXTURE_IDS = TEXTURE:id()
local MAT_CONFIG_IDS = MAT_CONFIG:id()
local SEQ_MANAGER_IDS = SEQ_MANAGER:id()
local COOKED_PHYSICS_IDS = COOKED_PHYSICS:id()

local CP_DEFAULT = BeardLib:GetPath() .. "Assets/units/default_cp.cooked_physics"
function C:LoadPackageConfig(directory, config, mod, temp)
    if not (SystemFS and SystemFS.exists) then
        BeardLib:log("[ERROR] SystemFS does not exist! Custom Packages cannot function without this! Do you have an outdated game version?")
        return
	end
	
	if not DB.create_entry then
		BeardLib:log("[ERROR] Create entry function does not exist, cannot add files.")
		return
	end

	if mod then
		local use_clbk = config.use_clbk and mod:StringToCallback(config.use_clbk) or nil
		if use_clbk and not use_clbk(config) then
			return
		end
	end
	
    if config.load_clbk and not config.load_clbk(config) then
        return
	end
	
    local loading = {}
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            local load_clbk = child.load_clbk
            if not load_clbk or load_clbk(path, typ) then
                if typ == UNIT_LOAD or typ == ADD then
                    self:LoadPackageConfig(directory, child)
                elseif typ and path then
                    path = Path:Normalize(path)
                    local ids_ext = Idstring(self.ext_convert[typ] or typ)
					local ids_path = Idstring(path)
					local file_path = child.full_path or Path:Combine(directory, config.file_path or path)
					local file_path_ext = file_path.."."..typ
                    if FileIO:Exists(file_path_ext) then
                        local load = child.force
                        if not load then
                            if child.force_if_not_loaded then
                                load = not PackageManager:has(ids_ext, ids_path)
                            else
                                load = not DB:has(ids_ext, ids_path)
                            end
                        end
						if load then
							if ids_ext == UNIT_IDS then
								local all = child.include_all
								local most = all or child.include_most
								if most or child.include_default then
									FileManager:AddFileWithCheck(MODEL_IDS, ids_path, file_path.."."..MODEL)
									FileManager:AddFileWithCheck(OBJECT_IDS, ids_path, file_path.."."..OBJECT)
									FileManager:AddFileWithCheck(MAT_CONFIG_IDS, ids_path, file_path.."."..MAT_CONFIG)
									if not DB:has(ids_ext, ids_path) then
										FileManager:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
									end
                                end
                                if child.include_cooked_physics then
                                    FileManager:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                                end
								if most or child.include_textures then
									FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_df"), file_path.."_df" .."."..TEXTURE)
									FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_nm"), file_path.."_nm" .."."..TEXTURE)
								end
								if all or child.include_sequence then
									FileManager:AddFileWithCheck(SEQ_MANAGER_IDS, ids_path, file_path.."."..SEQ_MANAGER)
								end
							end
							FileManager:AddFile(ids_ext, ids_path, file_path_ext)
                            if child.reload then
                                PackageManager:reload(ids_ext, ids_path)
                            end
                            if child.load then
                                table.insert(loading, {ids_ext, ids_path, file_path_ext})
							end
                        end
                    else
                        BeardLib:log("[ERROR] File does not exist! %s", tostring(file_path))
                    end
                else
                    BeardLib:log("[ERROR] Node in %s does not contain a definition for both type and path", tostring(directory))
                end                
            end
        end
    end

    if config.unload_on_restart or temp then
        table.insert(self.unload_on_restart, config)
    end

    --For some reason this needs to be here, instead of loading in the main loop or the game will go into a hissy fit 
    for _, file in pairs(loading) do
        FileManager:LoadAsset(unpack(file))
    end
end

function C:UnloadPackageConfig(config)
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = Path:Normalize(path)
                local ids_ext = Idstring(self.ext_convert[typ] or typ)
                local ids_path = Idstring(path)
                if DB:has(ids_ext, ids_path) then
                    if child.unload ~= false then
                        FileManager:UnLoadAsset(ids_ext, ids_path)
                    end
                    FileManager:RemoveFile(ids_ext, ids_path)
                end
            elseif typ == "unit_load" or typ == "add" then
                self:UnloadPackageConfig(child)
            else
                BeardLib:log("[ERROR] Some node does not contain a definition for both type and path")
            end
        end
    end
end

function C:Unload()
    for _, v in pairs(self.unload_on_restart) do
        self:UnloadPackageConfig(v)
    end
end