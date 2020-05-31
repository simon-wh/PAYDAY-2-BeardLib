local F = table.remove(RequiredScript:split("/"))
local SyncUtils = BeardLib.Utils.Sync

if F == "huskplayermovement" then
    Hooks:PostHook(PlayerMovement, "save", "BeardLib.Save", function(self, data)
        data.movement.outfit = SyncUtils:CleanOutfitString(data.movement.outfit)
    end)
    Hooks:PostHook(HuskPlayerMovement, "save", "BeardLib.Save", function(self, data)
        data.movement.outfit = SyncUtils:CleanOutfitString(data.movement.outfit)
    end)

    --Removes the need of thq material config for custom melee
    local mtr_cubemap = Idstring("mtr_cubemap")
    Hooks:PostHook(HuskPlayerMovement, "anim_cbk_spawn_melee_item", "BeardLibForceMeleeTHQ", function(self, unit, graphic_object)
        if alive(self._melee_item_unit) then
            local peer = managers.network:session():peer_by_unit(self._unit)
            local id = peer:melee_id()
            local tweak = tweak_data.blackmarket.melee_weapons[id]
            if tweak.custom then
                if tweak.auto_thq ~= false then
                    for _, material in ipairs(self._melee_item_unit:get_objects_by_type(Idstring("material"))) do
                        if material.id and material:id() == mtr_cubemap then
                            material:set_render_template(Idstring("generic:CUBE_ENVIRONMENT_MAPPING:DIFFUSE_TEXTURE:NORMALMAP"))
                        else
                            material:set_render_template(Idstring("generic:DIFFUSE_TEXTURE:NORMALMAP"))
                        end
                    end
                else
                    local new_material_config = Idstring(tweak.unit .. "_thq")
                    if DB:has(Idstring("material_config"), new_material_config) then
                        self._melee_item_unit:set_material_config(new_material_config, true)
                    end
                end
            end
        end
    end)
    Hooks:PostHook(TradeManager, "save", "BeardLib.Save", function(self, save_data)
        if save_data and save_data.trade and save_data.trade.outfits then
            for i, data in pairs(save_data.trade.outfits) do
                data.outfit = SyncUtils:CleanOutfitString(data.outfit)
            end
        end
    end)
elseif F == "playerinventory" then
    Hooks:PostHook(PlayerInventory, "_chk_create_w_factory_indexes", "CheckParts", function()
        local tbl = PlayerInventory._weapon_factory_indexed
        if tbl then
            local temp = clone(tbl)
            for _, id in pairs(temp) do
                if tweak_data.weapon.factory[id].custom then
                    table.delete(tbl, id)
                end
            end
        end
    end)
    local get_weapon_index = PlayerInventory._get_weapon_sync_index
    function PlayerInventory._get_weapon_sync_index(wanted_weap_name)
        return get_weapon_index(wanted_weap_name) or -1
    end

    Hooks:PostHook(PlayerInventory, "save", "BeardLib.Save", function(self, data)
        if self._equipped_selection then
            if data.equipped_weapon_index == -1 then
                local new_index, blueprint = SyncUtils:GetCleanedWeaponData(self._unit)
                data.equipped_weapon_index = new_index
                data.blueprint_string = blueprint
            end
        end
    end)
elseif F == "newraycastweaponbase" then
    --Gotta replace it all sadly.
    function NewRaycastWeaponBase:blueprint_to_string()
        local new_blueprint = SyncUtils:GetCleanedBlueprint(self._blueprint, self._factory_id)
        return managers.weapon_factory:blueprint_to_string(self._factory_id, new_blueprint)
    end
elseif F == "unitnetworkhandler" then
    local set_equipped_weapon = UnitNetworkHandler.set_equipped_weapon
    function UnitNetworkHandler:set_equipped_weapon(unit, item_index, blueprint_string, cosmetics_string, sender)
        if not self._verify_character(unit) then
            return
        end

        local peer = self._verify_sender(sender)

        if not peer then
            return
        end

        if peer._last_beardlib_weapon_string and peer:set_equipped_weapon_beardlib(peer._last_beardlib_weapon_string, "2.0") then
            peer._last_beardlib_weapon_string = nil
        else
            set_equipped_weapon(self, unit, item_index, blueprint_string, cosmetics_string, sender)
        end
    end
elseif F == "teamaibase" then
    Hooks:PostHook(TeamAIBase, "save", "BeardLib.Save", function(self, data)
        if data.base and data.base.loadout then
            data.base.loadout = SyncUtils:CleanOutfitString(data.base.loadout, true)
        end
    end)
end