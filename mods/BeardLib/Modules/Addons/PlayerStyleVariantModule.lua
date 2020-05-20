--[[

    Maintenance by Cpone (Cpone#8463 on Discord).
    Don't spam Luffy or whatever about this shite, this is all mine.

]]

PlayerStyleVariantModule = PlayerStyleVariantModule or class(ItemModuleBase)
PlayerStyleVariantModule.type_name = "PlayerStyleVariant"

function PlayerStyleVariantModule:RegisterHook()
	if not self._config.id then
        self:Err("Cannot add a Player Style Variant, no ID specified.")
        return
    end

    if not self._config.player_style_id then
        self:Err("Cannot add a Player Style Variant '%s', no Player Style ID specified.", self._config.id)
        return
    end

    self._config.name_id = self._config.name_id or ("bm_suit_" .. self._config.id)
    self._config.desc_id = self._config.desc_id or self._config.name_id .. "_desc"

    -- Super simple, just takes XML and shoves it into the player style stuff.
    Hooks:Add("BeardLibCreateCustomPlayerStyleVariants", self._config.id .. self._config.player_style_id .. "AddPlayerStyleVariantTweakData", function(ps_self)
        local config = self._config

        if not ps_self[config.player_style_id] then
            self:Err("Player Style with id '%s' doesn't exist when trying to create variant '%s'!", config.player_style_id, config.id)
            return
        end

        if ps_self[config.player_style_id].material_variations and ps_self[config.player_style_id].material_variations[config.id] then
            self:Err("Player Style Variant with id '%s' already exists for '%s'!", config.id, config.player_style_id)
            return
        end

        ps_self[config.player_style_id].material_variations = ps_self[config.player_style_id].material_variations or {}
        ps_self[config.player_style_id].material_variations[config.id] = table.merge({
        	unlocked = true,
            auto_acquire = true,
            custom = true
        }, config)
    end)
end

BeardLib:RegisterModule(PlayerStyleVariantModule.type_name, PlayerStyleVariantModule)