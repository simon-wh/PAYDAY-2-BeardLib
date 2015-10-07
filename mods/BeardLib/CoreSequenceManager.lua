if CoreSequenceManager then
	SequenceManager = CoreSequenceManager.SequenceManager
	CloneClass(SequenceManager)
	function SequenceManager.init(self, area_damage_mask, target_world_mask, beings_mask)
		self.orig.init(self, area_damage_mask, target_world_mask, beings_mask)
		-- I REALLY NEED A BETTER PLACE TO CALL THESE
		Hooks:Call("BeardLibSequencePostInit")
		Hooks:Call("BeardLibEnvironmenPostInit")
	end
	
	MaterialElement = CoreSequenceManager.MaterialElement
	MaterialElement.FUNC_MAP["texture"] = "set_texture"
	
	function MaterialElement:set_texture(env, old_material, key)
		local materials = env.dest_unit:get_objects_by_type(Idstring("material"))
		local texture = TextureCache:retrieve(string.gsub(self._parameters["texture"], "'", ""), "normal")
		if self._parameters["multiple_objects"] then
			log("multiple")
			for _, imaterial in pairs(materials) do
				if imaterial:name() == Idstring(string.gsub(self._parameters["name"], "'", "")) then
					Application:set_material_texture(imaterial, Idstring("diffuse_texture"), texture)
				end
			end
		else
			log("single")
			local name = self:run_parsed_func(env, self._name)
			local new_material = env.dest_unit:material(name:id())
			Application:set_material_texture(new_material, Idstring("diffuse_texture"), texture)
		end
	end
end