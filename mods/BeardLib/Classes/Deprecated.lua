function Deprected()
    BeardLib:log("%s is a deprecated function and does nothing anymore.",debug.getinfo(2).name)
end

--Same thing
BeardLib.Utils.Math = {}
BeardLib.managers = {}
BeardLib.modules = BeardLib.Modules

function BeardLib.Utils.Math:Round(val, dp) return math.round_with_precision(val, dp) end
QuickAnim = {Play = Deprected, Work = Deprected, Stop = Deprected, Working = Deprected, WorkColor = Deprected}
ModManager = {RegisterHook = Deprected, RegisterKeybind = Deprected, RegisterLibrary = Deprected}
math.QuaternionToEuler = Deprected
math.EulerToQuarternion = Deprected

-- kept for compatibility with mods designed for older BeardLib versions --
function BeardLib:ReplaceScriptData(replacement, replacement_type, target_path, target_ext, options)
	options = type(options) == "table" and options or {}
	BeardLib.Managers.File:ScriptReplaceFile(target_ext, target_path, replacement, table.merge(options, { type = replacement_type, mode = options.merge_mode }))
end