local F = table.remove(RequiredScript:split("/"))
if F == "huskplayermovement" then
    Hooks:PostHook(PlayerMovement, "save", "BeardLib.Save", function(self, data)
        data.movement.outfit = BeardLib.Utils:CleanOutfitString(data.movement.outfit)
    end)
    Hooks:PostHook(HuskPlayerMovement, "save", "BeardLib.Save", function(self, data)
        data.movement.outfit = BeardLib.Utils:CleanOutfitString(data.movement.outfit)        
    end)
    Hooks:PostHook(TradeManager, "save", "BeardLib.Save", function(self, save_data)
        if save_data and save_data.trade and save_data.trade.outfits then
            for i, data in pairs(save_data.trade.outfits) do
                data.outfit = BeardLib.Utils:CleanOutfitString(data.outfit)
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
                local new_index, blueprint = BeardLib.Utils:GetCleanedWeaponData(self._unit)
                data.equipped_weapon_index = index
                data.blueprint_string = blueprint
            end
        end
    end)

    --[[forces the game to call "set_eqiupped_weapon" which is the function that deals best with custom weapons.
    local add_unit_by_name = PlayerInventory.add_unit_by_name
    Hooks:PostHook(PlayerInventory, "add_unit_by_name", "BeardLib.AddUnitByName", function(self)
        if managers.player:player_unit():inventory() == self then
            self:_send_equipped_weapon()
        end
    end)

    Hooks:PostHook(PlayerInventory, "add_unit_by_factory_name", "BeardLib.AddUnitByFactoryName", function(self)
        if managers.player:player_unit():inventory() == self then
            managers.player:player_unit():inventory():_send_equipped_weapon()
        end
    end)]]
elseif F == "newraycastweaponbase" then
    --Gotta replace it all sadly.
    function NewRaycastWeaponBase:blueprint_to_string()
        local new_blueprint = BeardLib.Utils:GetCleanedBlueprint(self._blueprint, self._factory_id)
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
        
        if peer._last_beardlib_weapon_string then
            peer:set_equipped_weapon_beardlib(peer._last_beardlib_weapon_string, "1.0")
            peer._last_beardlib_weapon_string = nil
        else
            set_equipped_weapon(self, unit, item_index, blueprint_string, cosmetics_string, sender)
        end
    end
end