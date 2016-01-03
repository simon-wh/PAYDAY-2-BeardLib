core:module("CoreScriptViewport")
_ScriptViewport = _ScriptViewport or CoreScriptViewport._ScriptViewport

local BeardLib = _G.BeardLib

_ScriptViewport._init = _ScriptViewport.init


function _ScriptViewport.init(self, x, y, width, height, vpm, name)
	_ScriptViewport._init(self, x, y, width, height, vpm, name)
	BeardLib.CurrentViewportNo = BeardLib.CurrentViewportNo + 1
	self.__name = string.is_nil_or_empty( self.__name ) and BeardLib.CurrentViewportNo or self.__name
end