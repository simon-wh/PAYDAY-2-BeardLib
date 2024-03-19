BeardLibModPath = ModPath

_G.Global = {}
_G.Application = {}
_G.Application.ews_enabled = function() return false end
setmetatable(_G.Application, _G.Application)

require("core/lib/system/CoreModule")
core:register_module("core/lib/utils/CoreSerialize")
core:register_module("core/lib/utils/CoreCode")
core:register_module("core/lib/utils/CoreClass")
core:register_module("core/lib/utils/CoreDebug")
core:register_module("core/lib/utils/CoreTable")
core:register_module("core/lib/utils/CoreString")
core:register_module("core/lib/utils/CoreApp")
core:_copy_module_to_global("CoreCode")
core:_copy_module_to_global("CoreClass")
core:_copy_module_to_global("CoreDebug")
core:_copy_module_to_global("CoreTable")
core:_copy_module_to_global("CoreString")
core:_copy_module_to_global("CoreApp")

function Idstring(str)
	return str
end

function string:id()
	return Idstring(self)
end

dofile(BeardLibModPath .. "Core.lua")

-- Cleanup most of important globals that might accidentally trigger something else.
_G.core = nil
_G.Global = nil
_G.Application = nil