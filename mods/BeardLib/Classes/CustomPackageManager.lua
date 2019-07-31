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

function C:UnloadPackage(id)
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


local UNIT_ALL = "unit_all"
local UNIT_OBJ = "unit_obj"
local UNIT_TEX = "unit_tex"
local UNIT_MAT = "unit_mat"
local UNIT_SEQ = "unit_seq"
local UNIT_MAT_SEQ = "unit_mat_seq"
local UNIT_THQ = "unit_thq"
local UNIT_MAT_THQ = "unit_mat_thq"
local UNIT_NPC = "unit_npc"
local UNIT_CC = "unit_cc"
local UNIT_MAT_CC = "unit_mat_cc"
local UNIT_OBJ_SEQ = "unit_obj_seq"

--Default: unit, cooked phyiscs, model, object.

--tex: Adds material_config and textures. 
--mat: Adds material_config.
--mat_seq: Adds material_config and sequence_manager.
--seq: Adds material_config, textures and sequence_manager.
--obj_seq: Adds sequence manager.
--obj: Adds nothing.

--thq: Adds _thq, material config and textures.
--mat_thq: Adds _thq and material_config.
--npc: Adds _npc unit.
--cc: Adds _thq, _cc, material_config, textures and cc texture.
--mat_cc: Adds _thq, _cc and material_config.

local UNIT_SHORTCUTS = {
    [UNIT_OBJ] = true,
    [UNIT_TEX] = true,
    [UNIT_MAT] = true,
    [UNIT_SEQ] = true,
    [UNIT_MAT_SEQ] = true,
    [UNIT_THQ] = true,
    [UNIT_NPC] = true,
    [UNIT_CC] = true,
    [UNIT_MAT_CC] = true,
    [UNIT_MAT_THQ] = true,
    [UNIT_SIMPLE_SEQ] = true
}

local DF_NM = "df_nm"
local DF_NM_CC = "df_nm_cc"
local DF_NM_CC_GSMA = "df_nm_cc_gsma"
local DF_NM_GSMA = "df_nm_gsma"

local TEXTURE_SHORTCUTS = {
    [DF_NM] = true,
    [DF_NM_CC] = true,
    [DF_NM_CC_GSMA] = true,
    [DF_NM_GSMA] = true,
}

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
                elseif UNIT_SHORTCUTS[typ] then
                    local ids_path = Idstring(path)
                    local file_path = child.full_path or Path:Combine(directory, config.file_path or path)

                    FileManager:AddFileWithCheck(UNIT_IDS, ids_path, file_path.."."..UNIT)
                    if not child.custom_cp then
                        FileManager:AddFileWithCheck(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                    end

                    FileManager:AddFileWithCheck(MODEL_IDS, ids_path, file_path.."."..MODEL)
                    FileManager:AddFileWithCheck(OBJECT_IDS, ids_path, file_path.."."..OBJECT)

                    local mat = typ == UNIT_MAT
                    local mat_seq = typ == UNIT_MAT_SEQ
                    local seq = typ == UNIT_SEQ
                    local cc = typ == UNIT_CC
                    local mat_cc = typ == UNIT_MAT_CC
                    local thq = typ == UNIT_THQ
                    local mat_thq = typ == UNIT_MAT_THQ

                    if mat or tex or seq or mat_seq or thq or cc or mat_cc or mat_thq then
                        FileManager:AddFileWithCheck(MAT_CONFIG_IDS, ids_path, file_path.."."..MAT_CONFIG)
                        if tex or seq or cc or thq then
                            FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_df"), file_path.."_df".."."..TEXTURE)
                            FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_nm"), file_path.."_nm".."."..TEXTURE)
                        end
                        if seq or mat_seq then
                            FileManager:AddFileWithCheck(SEQ_MANAGER_IDS, ids_path, file_path.."."..SEQ_MANAGER)
                        end
                    end

                    if typ == UNIT_SEQ then
                        FileManager:AddFileWithCheck(SEQ_MANAGER_IDS, ids_path, file_path.."."..SEQ_MANAGER)
                    elseif typ == UNIT_NPC then
                        FileManager:AddFileWithCheck(UNIT_IDS, Idstring(path.."_npc"), file_path.."_npc."..UNIT)
                    end
            
                    if thq or typ == cc then
                        FileManager:AddFileWithCheck(UNIT_IDS, Idstring(path.."_thq"), file_path.."."..UNIT)
                    end
                    if cc or mat_cc then
                        if cc then
                            FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_df_cc"), file_path.."_df_cc".."."..TEXTURE)
                        end
                        FileManager:AddFileWithCheck(MAT_CONFIG_IDS, Idstring(path.."_cc"), file_path.."_cc."..MAT_CONFIG)
                        FileManager:AddFileWithCheck(MAT_CONFIG_IDS, Idstring(path.."_cc_thq"), file_path.."_cc_thq."..MAT_CONFIG)
                    end
                elseif TEXTURE_SHORTCUTS[typ] then
                    path = Path:Normalize(path)
                    local file_path = child.full_path or Path:Combine(directory, config.file_path or path)
                    FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_df"), file_path.."_df".."."..TEXTURE)
                    FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_nm"), file_path.."_nm".."."..TEXTURE)
                    if typ == DF_NM_CC or typ == DF_NM_CC_GSMA then
                        FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_df_cc"), file_path.."_df_cc".."."..TEXTURE)
                    end
                    if typ == DF_NM_GSMA or typ == DF_NM_CC_GSMA then
                        FileManager:AddFileWithCheck(TEXTURE_IDS, Idstring(path.."_gsma"), file_path.."_gsma".."."..TEXTURE)
                    end
                elseif typ and path then
                    path = Path:Normalize(path)
                    local ids_ext = Idstring(self.ext_convert[typ] or typ)
					local ids_path = Idstring(path)
					local file_path = child.full_path or Path:Combine(directory, config.file_path or path)
					local file_path_ext = file_path.."."..typ
                    if FileIO:Exists(file_path_ext) then
                        local load = NotNil(child.force, config.force)
                        if not load then
                            if child.force_if_not_loaded then
                                load = not PackageManager:has(ids_ext, ids_path)
                            else
                                load = not DB:has(ids_ext, ids_path)
                            end
                        end
                        if load then
                            if ids_ext == UNIT_IDS then
								if child.include_default then --Old
									FileManager:AddFileWithCheck(MODEL_IDS, ids_path, file_path.."."..MODEL)
									FileManager:AddFileWithCheck(OBJECT_IDS, ids_path, file_path.."."..OBJECT)
									FileManager:AddFileWithCheck(MAT_CONFIG_IDS, ids_path, file_path.."."..MAT_CONFIG)
									FileManager:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                                end
                                if not child.custom_cp and not DB:has(COOKED_PHYSICS_IDS, ids_path) then
                                    FileManager:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                                end
							end
                            if child.reload then
                                PackageManager:reload(ids_ext, ids_path)
                            end
                            if child.load then
                                table.insert(loading, {ids_ext, ids_path, file_path_ext})
							end
                        end
                    else
                        BeardLib:log("[ERROR] File does not exist! %s", tostring(file_path_ext))
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