core:module("CoreScriptViewport")
_ScriptViewport = _ScriptViewport or CoreScriptViewport._ScriptViewport

local BeardLib = _G.BeardLib

_ScriptViewport._init = _ScriptViewport.init


function _ScriptViewport.init(self, x, y, width, height, vpm, name)
	_ScriptViewport._init(self, x, y, width, height, vpm, name)
	BeardLib.CurrentViewportNo = BeardLib.CurrentViewportNo + 1
	self.__name = string.is_nil_or_empty( self.__name ) and BeardLib.CurrentViewportNo or self.__name
end

function _ScriptViewport:_update(nr, t, dt)
	local is_first_viewport = nr == 1
	local scene = self._render_params[1]
	self._vp:update()
	if self._env_editor_callback then
		self._env_editor_callback(self._env_handler, self._vp, scene, self)
	end
	self._env_handler:update(is_first_viewport, self._vp, dt)
	self._env_handler:apply(is_first_viewport, self._vp, scene)
end