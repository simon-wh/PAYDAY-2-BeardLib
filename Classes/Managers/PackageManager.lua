BeardLibPackageManager = BeardLibPackageManager or BeardLib:ManagerClass("Package")
Global.cmp = Global.cmp or {custom_loaded_packages = {}}

local Managers = BeardLib.Managers

function BeardLibPackageManager:init()
    self.custom_packages = {}
    self.unload_on_restart = {}

     -- Deprecated, try not to use.
    CustomPackageManager = self
    BeardLib.managers.package = self
end

function BeardLibPackageManager:RegisterPackage(id, directory, config)
    local schema = {
        func_name = "BeardLibPackageManager:RegisterPackage",
        params = {
            {type="string", allow_nil = false},
            {type="string", allow_nil = false},
            {type="table", allow_nil = false}
        }
    }
    if not BeardLib.Utils:CheckParamsValidity({id, directory, config}, schema) then
        return false
    end

    local id_key = id:key()
    if self.custom_packages[id_key] then
        self:Err("Package with ID '%s' already exists! Returning...", id)
        return false
    end

    self.custom_packages[id_key] = {dir = directory, config = config, id = id}

    return true
end

function BeardLibPackageManager:LoadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:LoadPackageConfig(pck.dir, pck.config)
        Global.cmp.custom_loaded_packages[id] = true
        return true
    end
    return false
end

function BeardLibPackageManager:UnloadPackage(id)
    id = id:key()
    if self.custom_packages[id] then
        local pck = self.custom_packages[id]
        self:UnloadPackageConfig(pck.config)
        Global.cmp.custom_loaded_packages[id] = false
        return true
    end
    return false
end

function BeardLibPackageManager:PackageLoaded(id)
    return Global.cmp.custom_loaded_packages[id:key()]
end

function BeardLibPackageManager:HasPackage(id)
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
--cc: Adds _thq, _cc, _cc_thq material_config, textures and cc texture.
--mat_cc: Adds _thq, _cc, _cc_thq and material_config.

BeardLibPackageManager.UNIT_SHORTCUTS = {
    unit_obj = {},
    unit_tex = {texture = {"_df", "_nm"}, material_config = true},
    unit_mat = {material_config = true},
    unit_seq = {sequence_manager = true, material_config = true, texture = {"_df", "_nm"}},
    unit_mat_seq = {sequence_manager = true, material_config = true},
    unit_thq = {material_config = {"_thq"}, texture = {"_df", "_nm"}},
    unit_npc = {unit = {"_npc"}},
    unit_cc = {material_config = {"_thq", "_cc", "_cc_thq"}, texture = {"_df", "_nm", "_df_cc"}},
    unit_mat_cc = {material_config = {"_thq", "_cc", "_cc_thq"}},
    unit_mat_thq = {material_config = {"_thq"}},
    unit_obj_seq = {sequence_manager = true}
}

BeardLibPackageManager.TEXTURE_SHORTCUTS = {
    df_nm = {"_df", "_nm"},
    df_nm_cc = {"_df", "_nm", "_df_cc"},
    df_nm_cc_gsma = {"_df", "_nm", "_df_cc", "_gsma"},
    df_nm_gsma = {"_df", "_nm", "_gsma"},
}

BeardLibPackageManager.EXT_CONVERT = {dds = "texture", png = "texture", tga = "texture", jpg = "texture", bik = "movie"}

local CP_DEFAULT = BeardLib:GetPath() .. "Assets/units/default_cp.cooked_physics"
function BeardLibPackageManager:LoadPackageConfig(directory, config, temp, skip_use_clbk)
    if not (SystemFS and SystemFS.exists) then
        self:Err("SystemFS does not exist! Custom Packages cannot function without this! Do you have an outdated game version?")
        return
	end

	if not DB.create_entry then
		self:Err("Create entry function does not exist, cannot add files.")
		return
	end

    if not skip_use_clbk then
        local use_clbk = config.use_clbk or config.load_clbk
        if use_clbk and self._mod then
            use_clbk = self._mod:StringToCallback(use_clbk) or nil
        end
    end
    if use_clbk and not use_clbk(config) then
        return
    end

    local ingame = Global.level_data and Global.level_data.level_id ~= nil
    local inmenu = not ingame

    local loading = {}
    for _, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            local use_clbk = child.use_clbk or child.load_clbk
            if use_clbk and self._mod then
                use_clbk = self._mod:StringToCallback(use_clbk) or nil
            end
            if not use_clbk or use_clbk(path, typ) then
                if typ == UNIT_LOAD or typ == ADD then
                    self:LoadPackageConfig(directory, child, nil, true)
                elseif BeardLibPackageManager.UNIT_SHORTCUTS[typ] then
                    local ids_path = Idstring(path)
                    local file_path = child.full_path or Path:Combine(directory, child.file_path or path)
                    local auto_cp = NotNil(child.auto_cp, config.auto_cp, true)
                    self:AddFileWithCheck(UNIT_IDS, ids_path, file_path.."."..UNIT)
                    if auto_cp then
                        self:AddFileWithCheck(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                    end

                    self:AddFileWithCheck(MODEL_IDS, ids_path, file_path.."."..MODEL)
                    self:AddFileWithCheck(OBJECT_IDS, ids_path, file_path.."."..OBJECT)

                    for load_type, load in pairs(BeardLibPackageManager.UNIT_SHORTCUTS[typ]) do
                        local type_ids = load_type:id()
                        if load_type ~= TEXTURE then
                            self:AddFileWithCheck(type_ids, Idstring(path), file_path.."."..load_type)
                        end
                        if type(load) == "table" then
                            for _, suffix in pairs(load) do
                                self:AddFileWithCheck(type_ids, Idstring(path..suffix), file_path..suffix.."."..load_type)
                            end
                        end
                    end
                elseif BeardLibPackageManager.TEXTURE_SHORTCUTS[typ] then
                    path = Path:Normalize(path)
                    local file_path = child.full_path or Path:Combine(directory, config.file_path or path)
                    for _, suffix in pairs(BeardLibPackageManager.TEXTURE_SHORTCUTS[typ]) do
                        Managers.File:AddFileWithCheck(TEXTURE_IDS, Idstring(path..suffix), file_path..suffix.."."..TEXTURE)
                    end
                elseif typ and path then
                    path = Path:Normalize(path)
                    local ids_ext = Idstring(BeardLibPackageManager.EXT_CONVERT[typ] or typ)
					local ids_path = Idstring(path)
					local file_path = child.full_path or Path:Combine(directory, config.file_path or path)
                    local file_path_ext = file_path.."."..typ
                    local auto_cp = NotNil(child.auto_cp, config.auto_cp, false)
                    local force = NotNil(child.force, config.force, true)
                    local reload = NotNil(child.reload, config.reload, false)
                    child.unload = NotNil(child.unload, config.unload, true)

                    local is_unit = ids_ext == UNIT_IDS
                    local dyn_load_game = NotNil(child.load_in_game, config.load_in_game, is_unit and string.ends(path, "_husk") or false)
                    local dyn_load_menu = NotNil(child.load_in_menu, config.load_in_menu, false)
                    local dyn_load = NotNil(child.load, config.load, false)

                    if FileIO:Exists(file_path_ext) then
                        local load = force
                        if not load then
                            local force_if_not_loaded = NotNil(child.force_if_not_loaded, config.force_if_not_loaded, false)
                            if force_if_not_loaded then
                                load = not PackageManager:has(ids_ext, ids_path)
                            else
                                load = not DB:has(ids_ext, ids_path)
                            end
                        end
                        if load then
                            if is_unit then
								if child.include_default then --Old
									Managers.File:AddFileWithCheck(MODEL_IDS, ids_path, file_path.."."..MODEL)
									Managers.File:AddFileWithCheck(OBJECT_IDS, ids_path, file_path.."."..OBJECT)
									Managers.File:AddFileWithCheck(MAT_CONFIG_IDS, ids_path, file_path.."."..MAT_CONFIG)
									Managers.File:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                                end
                                if auto_cp then
                                    Managers.File:AddFile(COOKED_PHYSICS_IDS, ids_path, CP_DEFAULT)
                                end
                            end
                            Managers.File:AddFile(ids_ext, ids_path, file_path_ext)
                            if child.reload then
                                PackageManager:reload(ids_ext, ids_path)
                            end
                            if dyn_load or (dyn_load_game and ingame) or (dyn_load_menu and not inmenu) then
                                table.insert(loading, {ids_ext, ids_path, file_path_ext})
							end
                        end
                    else
                        self:Err("File does not exist! %s", tostring(file_path_ext))
                    end
                elseif typ ~= "auto_generate" then
                    self:Err("Node in %s does not contain a definition for both type and path", tostring(directory))
                end
            end
        end
    end

    if config.unload_on_restart or temp then
        table.insert(self.unload_on_restart, config)
    end

    --Simon: For some reason this needs to be here, instead of loading in the main loop or the game will go into a hissy fit
    --Luffy: Most likely the reason behind this is that some assets are not added yet.
    for _, file in pairs(loading) do
        Managers.File:LoadAsset(unpack(file))
    end
end

function BeardLibPackageManager:Err(...)
    BeardLib:Err(...)
end

function BeardLibPackageManager:AddFileWithCheck(ext, path, file)
	if FileIO:Exists(file) then
		Managers.File:AddFile(ext, path, file)
	else
		self:Err("File does not exist! %s", tostring(file))
	end
end

function BeardLibPackageManager:UnloadPackageConfig(config)
    for i, child in ipairs(config) do
        if type(child) == "table" then
            local typ = child._meta
            local path = child.path
            if typ and path then
                path = Path:Normalize(path)
                local ids_ext = Idstring(self.EXT_CONVERT[typ] or typ)
                local ids_path = Idstring(path)
                if DB:has(ids_ext, ids_path) then
                    if child.unload ~= false then
                        Managers.File:UnloadAsset(ids_ext, ids_path)
                    end
                    Managers.File:RemoveFile(ids_ext, ids_path)
                end
            elseif typ == "unit_load" or typ == "add" then
                self:UnloadPackageConfig(child)
            else
                self:Err("Some node does not contain a definition for both type and path")
            end
        end
    end
end

function BeardLibPackageManager:Unload()
    for _, v in pairs(self.unload_on_restart) do
        self:UnloadPackageConfig(v)
    end
end