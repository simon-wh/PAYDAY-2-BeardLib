core:module("CoreEnvironmentManager")
core:import("CoreClass")
core:import("CoreEnvironmentHandler")
core:import("CoreEnvironmentFeeder")
EnvironmentManager = EnvironmentManager or CoreClass.class()
local EnvInit = EnvironmentManager.init
function EnvironmentManager:init(...)
	EnvInit(self, ...)
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
end