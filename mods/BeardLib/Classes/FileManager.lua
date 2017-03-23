_G.FileManager = {}

local fm = FileManager
fm.const = {
	h_preprocessSF = "BeardLibPreProcessScriptData",
	h_postprocessSF = "BeardLibProcessScriptData"
}

fm.process_modes = {
	merge = function(a1, a2) return table.merge(a1, a2) end,
	script_merge = function(a1, a2) return table.script_merge(a1, a2) end,
	add = function(a1, a2) return table.add(a1, a2) end,
	replace = ""
}
Global.fm = Global.fm or {}

--[ids_ext] = {ids_added_file, ...}
Global.fm.added_files = Global.fm.added_files or {}
-- [ids_ext] = { ids_modded_file = { id = {file, mode, ...}} }
fm.modded_files = {}

fm._files_to_load = {}
fm._files_to_unload = {}

Hooks:Register(fm.const.h_preprocessSF)
Hooks:Register(fm.const.h_postprocessSF)

function fm:Process(ids_ext, ids_path, name_mt)
	local data = {}
	if DB:_has(ids_ext, ids_path) then
        if name_mt ~= nil then
            data = PackageManager:_script_data(ids_ext, ids_path, name_mt)
        else
            data = PackageManager:_script_data(ids_ext, ids_path)
        end
	end

	Hooks:Call(self.const.h_preprocessSF, ids_ext, ids_path, data)
	local k_ext = ids_ext:key()
	local k_path = ids_path:key()
	local mods = self.modded_files[k_ext] and self.modded_files[k_ext][k_path]
	if mods then
		for id, mdata in pairs(mods) do
			if not mdata.clbk or mdata.clbk() then
				if mdata.mode and not self.process_modes[mdata.mode] then
					BeardLib:log("[ERROR] The process mode '%s' does not exist! Skipping...", data.mode)
				else
					local to_replace = (not mdata.mode or mdata.mode == "replace")
					if to_replace and #mods > 1 then
						BeardLib:log("[WARNING] Script Mod with ID:'%s', Path:'%s.%s' may potentially overwrite changes from other mods! Continuing...", tostring(data.id), k_path, k_ext)
					end
					local new_data = FileIO:ReadScriptDataFrom(mdata.file, mdata.type)
					if new_data then
                        if ids_ext == Idstring("nav_data") then
                            BeardLib.Utils:RemoveMetas(new_data)
                        elseif (ids_ext == Idstring("continents") or ids_ext == Idstring("mission")) and mdata.type=="custom_xml" then
                            BeardLib.Utils:RemoveAllNumberIndexes(new_data, true)
                        end

						if to_replace then
							data = new_data
						else
							fm.process_modes[mdata.mode](data, new_data)
						end
					else
						BeardLib:log("[ERROR] The file '%s' does not exist!", mdata.file)
					end
				end
			end
		end
	end

	Hooks:Call(self.const.h_postprocessSF, ids_ext, ids_path, data)

	return data
end

function fm:AddFile(ext, path, file)
	if not DB.create_entry then
		BeardLib:log("[ERROR] Cannot add files!")
		return
	end
	--Add check for supported file types (or unsupported) to give warning
    DB:create_entry(ext:id(), path:id(), file)
    local k_ext = ext:key()
    Global.fm.added_files[k_ext] = Global.fm.added_files[k_ext] or {}
    Global.fm.added_files[k_ext][path:key()] = true
end

function fm:RemoveFile(ext, path)
	ext = ext:id()
	path = path:id()
	local k_ext = ext:key()
	local k_path = path:key()
	if Global.fm.added_files[k_ext] and Global.fm.added_files[k_ext][k_path] then
		self:UnLoadAsset(ext, path)
		DB:remove_entry(ext, path)
		Global.fm.added_files[k_ext][k_path] = nil
	end
end

function fm:ScriptAddFile(path, ext, file, options)
	self:ScriptReplaceFile(path, ext, file, options)
end

function fm:ScriptReplaceFile(ext, path, file, options)
    local ids_ext = ext:id()
	local ids_path = path:id()

    if options ~= nil and type(options) ~= "table" then
        BeardLib:log("[ERROR] %s:ReplaceScriptData parameter 5, expected table, got %s", self.Name, tostring(type(extra_data)))
        return
    end
    if not io.file_is_readable(file) then
        BeardLib:log("[ERROR] Lua state is unable to read file '%s'!", file)
        return
    end

    options = options or {}
	local k_ext = ids_ext:key()
	local k_path = ids_path:key()
	fm.modded_files[k_ext] = fm.modded_files[k_ext] or {}
	fm.modded_files[k_ext][k_path] = fm.modded_files[k_ext][k_path] or {}
	--Potentially move to [id] = options
	table.insert(fm.modded_files[k_ext][k_path], table.merge(options, {file = file}))
end

function fm:Has(ext, path)
	local k_ext = ext:key()
	return Global.fm.added_files[k_ext] and Global.fm.added_files[k_ext][path:key()]
end

function fm:HasScriptMod(ext, path)
	local k_ext = ext:key()
	return self.modded_files[k_ext] and self.modded_files[k_ext][path:key()]
end

local _LoadAsset = function(ids_ext, ids_path)
    if not managers.dyn_resource:has_resource(ids_ext, ids_path, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
        BeardLib:log("loaded file %s.%s", ids_path:key(), ids_ext:key())
        managers.dyn_resource:load(ids_ext, ids_path, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
    end
end

local _UnLoadAsset = function(ids_ext, ids_path)
    if managers.dyn_resource:has_resource(ids_ext, ids_path, managers.dyn_resource.DYN_RESOURCES_PACKAGE) then
        BeardLib:log("unloaded file %s.%s", ids_path:key(), ids_ext:key())
        managers.dyn_resource:unload(ids_ext, ids_path, managers.dyn_resource.DYN_RESOURCES_PACKAGE)
    end
end

function fm:LoadAsset(ids_ext, ids_path)
	ids_ext = ids_ext:id()
	ids_path = ids_path:id()
    if not managers.dyn_resource then
        table.insert(self._files_to_load, {ids_ext, ids_path})
        return
    end

    _LoadAsset(ids_ext, ids_path)
end

function fm:UnLoadAsset(ids_ext, ids_path)
	ids_ext = ids_ext:id()
	ids_path = ids_path:id()
    if not managers.dyn_resource then
        table.insert(self._files_to_unload, {ids_ext, ids_path})
        return
    end

    _UnLoadAsset(ids_ext, ids_path)
end

function fm:update(t,dt)
    if #self._files_to_load > 0 and managers.dyn_resource then
        local ids_ext, ids_path = unpack(table.remove(self._files_to_load))
        _LoadAsset(ids_ext, ids_path)
    end

	if #self._files_to_unload > 0 and managers.dyn_resource then
        local ids_ext, ids_path = unpack(table.remove(self._files_to_unload))
        _UnLoadAsset(ids_ext, ids_path)
    end
end

return fm