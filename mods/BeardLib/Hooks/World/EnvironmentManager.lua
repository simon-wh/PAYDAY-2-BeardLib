--Sky texture code.
core:import("CoreClass")
core:import("CoreEnvironmentHandler")
core:import("CoreEnvironmentFeeder")
core:module("CoreEnvironmentManager")

EnvironmentManager = EnvironmentManager or CoreClass.class()
Hooks:PostHook(EnvironmentManager, "init", "BeardLib.Init", function(self)
	local feeder_class = CoreEnvironmentFeeder.SkyTexturePathFeeder
	self._feeder_class_map[feeder_class.DATA_PATH_KEY] = feeder_class
	if feeder_class.FILTER_CATEGORY then
		local filter_list = self._predefined_environment_filter_map[feeder_class.FILTER_CATEGORY]
		if not filter_list then
			filter_list = {}
			self._predefined_environment_filter_map[feeder_class.FILTER_CATEGORY] = filter_list
		end
		table.insert(filter_list, feeder_class.DATA_PATH_KEY)
	end
end)

CoreEnvironmentFeeder.SkyTexturePathFeeder = CoreEnvironmentFeeder.SkyTexturePathFeeder or CoreClass.class(CoreEnvironmentFeeder.StringFeeder)
local SkyTex = CoreEnvironmentFeeder.SkyTexturePathFeeder
SkyTex.APPLY_GROUP_ID = CoreEnvironmentFeeder.Feeder.get_next_id()
SkyTex.DATA_PATH_KEY = Idstring("others/sky_texture"):key()
SkyTex.IS_GLOBAL = true
SkyTex.FILTER_CATEGORY = "Sky texture path"
function SkyTex:apply(handler, viewport, scene)
	if self._current and Underlay:loaded() then
		local texture = self._current
		if texture then
		    local material = Underlay:material(Idstring("sky"))
		    if material and DB:has(Idstring("texture"), texture:id()) then
		        Application:set_material_texture(material, Idstring("diffuse_texture"), texture:id(), Idstring("normal"))
		    end
		end
	end
end