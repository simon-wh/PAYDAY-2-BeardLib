--[[

    Maintenance by Sora (Sora#5529 on Discord).
    Please don't spam Luffy about eventual mess caused by this module. I suck at working with BreadLib. Thank you.

]]

WeaponSkinModule = WeaponSkinModule or class(ItemModuleBase)
WeaponSkinModule.type_id = "WeaponSkin"

function WeaponSkinModule:RegisterHook()
    self._config.id = self._config.id or self:log("[ERROR] Cannot add a weapon skin : No ID specified.")
    self._config.weapon_id = self._config.weapon_id or "amcar"
    self._config.weapon_ids = self._config.weapon_ids or nil
    self._config.name = self._config.name or "weapon_skin_name empty..."
    self._config.desc = self._config.desc or "bm_wskn_p90_woodland_desc" -- These descs are 99% of the time empty, excepted for legendaries :|
    self._config.rarity = self._config.rarity or "common"
    self._config.skin_folder = self._config.skin_folder and self:GetPath(self._config.skin_folder) or self:log("[ERROR] The weapon skin '%s' is not shipped with the skin folder.", self._config.skin_folder)
    self._config.locked = self._config.locked or nil
    self._config.unique_name = self._config.unique_name and self._config.name or nil

    if self._config.skin_attachments then
        self._skin_attachments = self._config.skin_attachments

        for k, v in pairs(self._skin_attachments) do
            if k == "_meta" then
                table.remove_key( self._skin_attachments, "_meta" )
            end
        end
    end

    self._assets_folders = self._config.skin_folder

    local skin_data = WeaponSkinExtension:new(self._assets_folders, self._config.id)

    self._skin_design = {
        base_gradient = skin_data:get_base_gradient(),
        pattern_gradient = skin_data:get_pattern_gradient(),
        pattern = skin_data:get_pattern(),
        pattern_tweak = skin_data:get_pattern_tweak(),
        pattern_pos = skin_data:get_pattern_pos(),
        sticker = skin_data:get_sticker(),
        uv_scale = skin_data:get_uv_scale(),
        uv_offset_rot = skin_data:get_uv_offset_rot(),
        cubemap_pattern_control = skin_data:get_cubemap_pattern_control(),
        types = skin_data:get_types(),
        parts = skin_data:get_parts()
    }

    Hooks:PostHook( DLCTweakData, "init", self._config.id .. "_AddSkinInventory", function(dlc_self)
        table.insert( dlc_self.starter_kit.content.loot_drops,
            {
                type_items = "weapon_skins",
                item_entry = self._config.id,
                global_value = "normal"
            }
        )
    end)

    Hooks:PostHook(BlackMarketTweakData, "_init_weapon_skins", self._config.id .. "_AddSkinData", function(bm_self)
        if bm_self.weapon_skins[self._config.id] then
            self:log("[ERROR] The weapon skin '%s' already exists in the tweak data table.", self._config.id)
            return
        end

        local config = self._config

        bm_self.weapon_skins[config.id] = {
            name_id = config.name,
            desc_id = config.desc,
            weapon_id = config.weapon_id,
            weapon_ids = config.weapon_ids, -- Ovk are a bunch of retards sometimes
            rarity = config.rarity,
            is_a_unlockable = true,
            custom = true,
            locked = config.locked,
            unique_name_id = config.unique_name,
            texture_bundle_folder = self._config.id,
            bonus = "recoil_p1", -- Aint gonna code a "statboost" version cause nobody would care for one. It's just to fill the table.
            reserve_quality = true,
            base_gradient = self._skin_design.base_gradient,
            pattern_gradient = self._skin_design.pattern_gradient,
            pattern = self._skin_design.pattern,
            pattern_tweak = self._skin_design.pattern_tweak,
            pattern_pos = self._skin_design.pattern_pos,
            sticker = self._skin_design.sticker,
            uv_scale = self._skin_design.uv_scale,
            uv_offset_rot = self._skin_design.uv_offset_rot,
            cubemap_pattern_control = self._skin_design.cubemap_pattern_control,
            types = self._skin_design.types,
            parts = self._skin_design.parts,
            default_blueprint = self._skin_attachments
        }
        --self:log("Added skin '%s' to the weapon '%s'", config.id, config.weapon_id)
    end)
end

BeardLib:RegisterModule(WeaponSkinModule.type_id, WeaponSkinModule)
