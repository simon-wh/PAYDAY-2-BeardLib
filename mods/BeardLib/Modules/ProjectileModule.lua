--Currently untested properly and will not sync projectiles that clients don't have!

ProjectileModule = ProjectileModule or class(ItemModuleBase)
ProjectileModule.type_name = "Projectile"

function ProjectileModule:RegisterHook()
	local config = self._config
	local id = config.id

    config.default_amount = config.default_amount and tonumber(config.default_amount) or 1
	config.global_value = config.global_value or self.defaults.global_value
	
	Hooks:Add("BeardLibCreateCustomProjectiles", id .. "AddProjectileTweakData", function(bm_self)
		local p_self = bm_self.projectiles

		p_self[id] = table.merge(deep_clone(p_self[self:GetBasedOn(p_self)]), table.merge({
			texture_bundle_folder = "mods",
            name_id = "bm_" .. id,
            desc_id = "bm_" .. id .. "_desc",
            custom = true
		}, config))
		
		if not table.contains(bm_self._projectiles_index, id) then
			table.insert(bm_self._projectiles_index, id)
		end
	end)

	Hooks:Add("BeardLibPostCreateCustomProjectiles", id .. "PostAddProjectileTweakData", function(tweak)
		tweak.projectiles[id] = table.merge(deep_clone(tweak[self:GetBasedOn(tweak.projectiles)]), table.merge({
            name_id = "bm_" .. id,
			custom = true
		}, config))
	end)

	Hooks:PostHook(UpgradesTweakData, "init", id .. "AddProjectileUpgradesData", function(u_self)
		local based_on = u_self.definitions[self:GetBasedOn(u_self.definitions)]
        u_self.definitions[id] = {
            category = based_on and based_on.category or "grenade",
            dlc = based_on and based_on.dlc
		}
        if config.unlock_level then
            u_self.level_tree[config.unlock_level] = u_self.level_tree[config.unlock_level] or {upgrades = {}, name_id = "weapons"}
            table.insert(u_self.level_tree[config.unlock_level].upgrades, id)
        end
    end)
end

local default_proj = "frag_com"
function ProjectileModule:GetBasedOn(p_self, based_on)
    p_self = p_self or tweak_data.blackmarket.projectiles
    based_on = based_on or self._config.based_on
    if based_on and p_self[based_on] then
        return based_on
    else
        return default_proj
    end
end

BeardLib:RegisterModule(ProjectileModule.type_name, ProjectileModule)