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
end