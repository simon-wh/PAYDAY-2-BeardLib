local orig = CrewManagementGui.populate_primaries
--Blocks out unsupported custom weapons
function CrewManagementGui:populate_primaries(i, data, ...)
    local res = orig(self, i, data, ...)
    for k, v in ipairs(data) do
        local fac_id = managers.weapon_factory:get_factory_id_by_weapon_id(v.name)
        if fac_id then
            local factory = tweak_data.weapon.factory[fac_id.."_npc"]
            if factory and factory.custom and not PackageManager:has(Idstring("unit"), factory.unit:id()) then
                v.buttons = {} 
                v.unlocked = false
                v.lock_texture = "guis/textures/pd2/lock_incompatible"
                v.lock_text = managers.localization:text("menu_data_crew_not_allowed")
            end
        end
    end
    return res
end