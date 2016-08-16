function PlayerInventory._chk_create_w_factory_indexes()
	if PlayerInventory._weapon_factory_indexed then
		return
	end
	local weapon_factory_indexed = {}
	--local full_weapon_factory_indexed = {}
	PlayerInventory._weapon_factory_indexed = weapon_factory_indexed
	--PlayerInventory._full_weapon_factory_indexed = full_weapon_factory_indexed
	for id, data in pairs(tweak_data.weapon.factory) do
		if id ~= "parts" and data.unit and not data.custom then
			--[[if data.custom then
				table.insert(full_weapon_factory_indexed, id)
			end]]
			table.insert(weapon_factory_indexed, id)
		end
	end
	table.sort(weapon_factory_indexed, function(a, b)
		return a < b
	end)
	--[[table.sort(full_weapon_factory_indexed, function(a, b)
		return a < b
	end)]]
end

local orig_PlayerInventory_get_weapon_sync_index = PlayerInventory._get_weapon_sync_index
function PlayerInventory._get_weapon_sync_index(wanted_weap_name)
    return orig_PlayerInventory_get_weapon_sync_index(wanted_weap_name) or -1
end

local orig_PlayerInventory_save = PlayerInventory.save
function PlayerInventory:save(data)
	orig_PlayerInventory_save(self, data)
	if self._equipped_selection then
		if data.equipped_weapon_index == -1 then
			local new_index, blueprint = BeardLib.Utils:GetCleanedWeaponData(self._unit)
			data.equipped_weapon_index = index
			data.blueprint_string = blueprint
		end
	end
end

--[[local orig_PlayerInventory_load = PlayerInventory.load
function PlayerInventory:load(data)

	orig_PlayerInventory_load(self, data)
	if data.equipped_weapon_index then
		self._weapon_add_clbk = "playerinventory_load"
		local delayed_data = {}
		delayed_data.equipped_weapon_index = data.equipped_weapon_index
		delayed_data.blueprint_string = data.blueprint_string
		delayed_data.cosmetics_string = data.cosmetics_string
		delayed_data.gadget_on = data.gadget_on
		managers.enemy:add_delayed_clbk(self._weapon_add_clbk, callback(self, self, "_clbk_weapon_add", delayed_data), Application:time() + 1)
	end
	self._mask_visibility = data.mask_visibility and true or false
end]]
