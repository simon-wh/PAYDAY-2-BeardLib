core:module("CoreEnvironmentFeeder")
core:import("CoreClass")
core:import("CoreCode")
core:import("CoreEngineAccess")
SkyTexturePathFeeder = SkyTexturePathFeeder or CoreClass.class(StringFeeder)
SkyTexturePathFeeder.APPLY_GROUP_ID = Feeder.get_next_id()
SkyTexturePathFeeder.DATA_PATH_KEY = Idstring("others/sky_texture"):key()
SkyTexturePathFeeder.IS_GLOBAL = true
SkyTexturePathFeeder.FILTER_CATEGORY = "Sky texture path"
function SkyTexturePathFeeder:apply(handler, viewport, scene)
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