function Deprected()
    BeardLib:log("%s is a deprecated function and does nothing anymore.",debug.getinfo(2).name)
end

--Same thing
BeardLib.Utils.Math = {}
function BeardLib.Utils.Math:Round(val, dp) return math.round_with_precision(val, dp) end
QuickAnim = {Play = Deprected, Work = Deprected, Stop = Deprected, Working = Deprected, WorkColor = Deprected}
ModManager = {RegisterHook = Deprected, RegisterKeybind = Deprected, RegisterLibrary = Deprected}
math.QuaternionToEuler = Deprected
math.EulerToQuarternion = Deprected