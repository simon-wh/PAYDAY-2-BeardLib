--[[

    Maintenance by Cpone (Cpone#8463 on Discord).
    Don't spam Luffy or whatever about this shite, this is all mine.

]]

PlayerStyleModule = PlayerStyleModule or BeardLib:ModuleClass("PlayerStyle", ItemModuleBase)

function PlayerStyleModule:RegisterHook()
    if not self._config.id then
        self:Err("Cannot add a Player Style, no ID specified.")
        return
    end

    self._config.name_id = self._config.name_id or ("bm_suit_" .. self._config.id)
    self._config.desc_id = self._config.desc_id or self._config.name_id .. "_desc"

    -- Make sure that any variants added through this are set to be custom.
    if self._config.material_variations then
        for variant_id, variant in pairs(self._config.material_variations) do
            -- Gotta do this otherwise they can't be overridden by false.
            if variant.custom == nil then variant.custom = true end
            if variant.auto_acquire == nil then variant.auto_acquire = true end
        end
    end

    -- Super simple, just takes XML and shoves it into the player style stuff.
    Hooks:Add("BeardLibCreateCustomPlayerStyles", self._config.id .. "AddPlayerStyleTweakData", function(ps_self)
        local config = self._config

        if ps_self[config.id] then
            self:Err("Player Style with id '%s' already exists!", config.id)
            return
        end

        ps_self[config.id] = table.merge({
            unlocked = true,
            auto_acquire = true,
            custom = true
        }, config)
    end)
end