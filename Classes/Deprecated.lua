function Deprecated()
    BeardLib:log("%s is a deprecated function and does nothing anymore.",debug.getinfo(2).name)
end

--Same thing
BeardLib.Utils.Math = {}
BeardLib.modules = BeardLib.Modules

function BeardLib.Utils.Math:Round(val, dp) return math.round_with_precision(val, dp) end
QuickAnim = {Play = Deprecated, Work = Deprecated, Stop = Deprecated, Working = Deprecated, WorkColor = Deprecated}
ModManager = {RegisterHook = Deprecated, RegisterKeybind = Deprecated, RegisterLibrary = Deprecated}
math.QuaternionToEuler = Deprecated
math.EulerToQuarternion = Deprecated

-- kept for compatibility with mods designed for older BeardLib versions --
function BeardLib:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
	options = type(options) == "table" and options or {}
	BeardLib.Managers.File:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
end

ModAssetUpdateManager = {
    UpdatesIgnored = Deprecated,
    RegisterUpdate = Deprecated,
    IsReadyForUpdate = Deprecated,
    SetUpdatesIgnored = Deprecated,
    CheckUpdateStatus = Deprecated,
    save_manager_file = Deprecated,
    load_manager_file = Deprecated,
    SetUpdateStatus = Deprecated,
    Update = Deprecated
}

BeardLib.managers = {
    asset_update = ModAssetUpdateManager
}