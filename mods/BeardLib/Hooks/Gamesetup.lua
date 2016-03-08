function GameSetup:init_game()
	local gsm = Setup.init_game(self)
	local engine_package = PackageManager:package("engine-package")
	engine_package:unload_all_temp()
	managers.mission:set_mission_filter(managers.job:current_mission_filter() or {})
	local level = Global.level_data.level
	local mission = Global.level_data.mission
	local world_setting = Global.level_data.world_setting
	local level_class_name = Global.level_data.level_class_name
	local level_class = level_class_name and rawget(_G, level_class_name)
	if level then
		if level_class then
			script_data.level_script = level_class:new()
		end
		local level_path = "levels/" .. tostring(level)
		local t = {
			file_path = level_path .. "/world",
			file_type = "world",
			world_setting = world_setting
		}
		self._world_holder = WorldHolder:new(t)
		self._world_holder:create_world("world", "all", Vector3())
		local mission_params = {
			file_path = level_path .. "/mission",
			activate_mission = mission,
			stage_name = "stage1"
		}
		managers.mission:parse(mission_params)
	else
		error("No level loaded! Use -level 'levelname'")
	end
	managers.worlddefinition:init_done()
	return gsm
end
