if CoreSequenceManager then
	SequenceManager = CoreSequenceManager.SequenceManager
	CloneClass(SequenceManager)
    
    Hooks:Register("BeardLibCreateScriptDataMods")
    Hooks:PostHook(SequenceManager, "init", "BeardLibSequenceManagerPostInit", function() 
        Hooks:Call("BeardLibCreateScriptDataMods")
    end)
	
	MaterialElement = CoreSequenceManager.MaterialElement
	MaterialElement.FUNC_MAP["texture"] = "set_texture"
	
	function MaterialElement:set_texture(env, old_material, key)
		local materials = env.dest_unit:get_objects_by_type(Idstring("material"))
		local texture = TextureCache:retrieve(string.gsub(self._parameters["texture"], "'", ""), "normal")
		if self._parameters["multiple_objects"] then
			for _, imaterial in pairs(materials) do
				if imaterial:name() == Idstring(string.gsub(self._parameters["name"], "'", "")) then
					Application:set_material_texture(imaterial, Idstring("diffuse_texture"), texture)
				end
			end
		else
			local name = self:run_parsed_func(env, self._name)
			local new_material = env.dest_unit:material(name:id())
			Application:set_material_texture(new_material, Idstring("diffuse_texture"), texture)
		end
	end
end