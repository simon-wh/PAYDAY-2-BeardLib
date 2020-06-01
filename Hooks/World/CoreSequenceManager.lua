if CoreSequenceManager then
    Hooks:Register("BeardLibCreateScriptDataMods")
    Hooks:PostHook(CoreSequenceManager.SequenceManager, "init", "BeardLibSequenceManagerPostInit", function() 
        Hooks:Call("BeardLibCreateScriptDataMods")
    end)

	local MaterialElement = CoreSequenceManager.MaterialElement
	MaterialElement.FUNC_MAP.texture = "set_texture"

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
	--Fixes some random crash
	local BodyElement = CoreSequenceManager.BodyElement
	function BodyElement.load(unit, data)
		for body_id, cat_data in pairs(data) do
			for _, sub_data in pairs(cat_data) do
				local body = unit:body(body_id)
				local param = sub_data[2]
				if type(param) == "string" then
					param = Idstring(param)
				end
				if body then
					body[sub_data[1]](body, param)
				end
			end
		end
	end
end
