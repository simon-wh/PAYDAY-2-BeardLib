
-- When we load the VR menu, lay down a flag we can use later
-- to distinguish this from a normal level
function MenuManagerVR:_load_scene()
	self._menu_unit = World:spawn_unit(Idstring("units/pd2_dlc_vr/menu/vr_menu"), Vector3(), Rotation())

	self._menu_unit:set_visible(false)

	local level_path = "levels/vr/menu"
	local t = {
		file_type = "world",
		file_path = level_path .. "/world",
		__bl_vr_main_menu = true
	}

	assert(WorldHolder:new(t):create_world("world", "statics", Vector3()), "Cant load the level!")
end
