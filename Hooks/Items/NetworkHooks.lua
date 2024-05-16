-- Contains a bunch of hooks to make custom items work. Mostly networking code.

local F = table.remove(RequiredScript:split("/"))
local SyncUtils = BeardLib.Utils.Sync
local SyncConsts = BeardLib.Constants.Sync

if F == "huskplayermovement" then
----------------------------------------------------------------
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
----------------------------------------------------------------
elseif F == "playerinventory" then
----------------------------------------------------------------
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
            if data.inventory and data.inventory.equipped_weapon_index == -1 then
                local new_index, blueprint = SyncUtils:GetCleanedWeaponData(self._unit)
                data.inventory.equipped_weapon_index = new_index
                data.inventory.blueprint_string = blueprint
            end
        end
    end)
----------------------------------------------------------------
elseif F == "newraycastweaponbase" then
    --Gotta replace it all sadly.
    function NewRaycastWeaponBase:blueprint_to_string()
        local new_blueprint = SyncUtils:GetCleanedBlueprint(self._blueprint, self._factory_id)
        return managers.weapon_factory:blueprint_to_string(self._factory_id, new_blueprint)
    end
----------------------------------------------------------------
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

        --There is no way the beardlib weapon string is set without passing the version check. So we have no problem assuming it's set to the latest one.
        if peer._last_beardlib_weapon_string and peer:set_equipped_weapon_beardlib(peer._last_beardlib_weapon_string, SyncConsts.WeaponVersion) then
            peer._last_beardlib_weapon_string = nil
        else
            set_equipped_weapon(self, unit, item_index, blueprint_string, cosmetics_string, sender)
        end
    end
----------------------------------------------------------------
elseif F == "groupaistatebase" then
    Hooks:PreHook(GroupAIStateBase, "set_unit_teamAI", "BeardLibSetUnitTeamAIExtraLoadout", function(self, unit, character_name, team_id, visual_seed, loadout)
        if unit and alive(unit) then
            local loadout_index = managers.criminals._loadout_map[character_name] or 1
            local extra_loadout = unit:base():beardlib_extra_loadout() or SyncUtils:ExtraOutfit(true, loadout_index)

            if extra_loadout then
                Hooks:Call("BeardLibExtraOutfitReload", unit, character_name, extra_loadout)
                unit:base():set_beardlib_extra_loadout(extra_loadout)
            end
        end
    end)
----------------------------------------------------------------
elseif F == "teamaibase" then
    function TeamAIBase:beardlib_extra_loadout()
        return self._beardlib_extra_loadout
    end

    function TeamAIBase:set_beardlib_extra_loadout(extra_loadout)
        self._beardlib_extra_loadout = extra_loadout
    end

    Hooks:PostHook(TeamAIBase, "save", "BeardLib.TeamAIBase.Save", function(self, data)
        if data.base then
            data.base.beardlib_loadout = data.base.loadout
            data.base.beardlib_extra_loadout = SyncUtils:BeardLibDataToJSON(self._beardlib_extra_loadout or {})

            if data.base.loadout then
                data.base.loadout = SyncUtils:CleanOutfitString(data.base.loadout, true)
            end
        end
    end)
----------------------------------------------------------------
elseif F == "huskteamaibase" then
    HuskTeamAIBase.beardlib_extra_loadout = TeamAIBase.beardlib_extra_loadout
    HuskTeamAIBase.set_beardlib_extra_loadout = TeamAIBase.set_beardlib_extra_loadout

    Hooks:PreHook(HuskTeamAIBase, "load", "BeardLib.TeamAIBase.Load", function(self, data)
        if data.base then
            if data.base.beardlib_loadout then
                data.base.loadout = data.base.beardlib_loadout
            end

            if data.base.beardlib_extra_loadout then
                self:set_beardlib_extra_loadout(SyncUtils:BeardLibJSONToData(data.base.beardlib_extra_loadout))
            end
        end
    end)
----------------------------------------------------------------
elseif F == "basenetworksession" then
    Hooks:PostHook(BaseNetworkSession, "create_local_peer", "BeardLibExtraOutfitCreateLocal", function(self, load_outfit)
        if load_outfit then
            self._local_peer:set_extra_outfit_string_beardlib(BeardLib.Utils.Sync:ExtraOutfitString())
        end
    end)
----------------------------------------------------------------
elseif F == "networkpeer" then
    local tradable_item_verif = NetworkPeer.tradable_verify_outfit
    function NetworkPeer:tradable_verify_outfit(signature)
        local outfit = self:blackmarket_outfit()

        if outfit.primary and outfit.primary.cosmetics and tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id] then
            if tweak_data.blackmarket.weapon_skins[outfit.primary.cosmetics.id].is_a_unlockable  then
                return
            end
        else
            return
        end

        if outfit.secondary and outfit.secondary.cosmetics and tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id] then
            if tweak_data.blackmarket.weapon_skins[outfit.secondary.cosmetics.id].is_a_unlockable  then
                return
            end
        else
            return
        end

        return tradable_item_verif(self, signature)
    end
----------------------------------------------------------------
elseif F == "menumanager" then
    Hooks:PostHook(MenuManager, "setup_local_lobby_character", "BeardLibExtraOutfitSetupLocalLobby", function(self)
        managers.network:session():local_peer():set_extra_outfit_string_beardlib(SyncUtils:ExtraOutfitString())
    end)

    Hooks:PostHook(MenuCallbackHandler, "_update_outfit_information", "BeardLibExtraOutfitUpdateLocalOutfit", function(self)
        if managers.network:session() then
            managers.network:session():local_peer():set_extra_outfit_string_beardlib(SyncUtils:ExtraOutfitString())
        end
    end)
----------------------------------------------------------------
----------------------------------------------------------------
elseif F == "connectionnetworkhandler" then
    --Sets the correct data out of NetworkPeer instead of straight from the parameters
    Hooks:PostHook(ConnectionNetworkHandler, "sync_outfit", "BeardLibSyncOutfitProperly", function(self, outfit_string, outfit_version, outfit_signature, sender)
        local peer = self._verify_sender(sender)
        if not peer then
            return
        end

        peer:beardlib_reload_outfit()
    end)
end