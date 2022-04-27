EquipmentsModule = EquipmentsModule or BeardLib:ModuleClass("Equipments", ItemModuleBase)
EquipmentsModule.required_params = {}

function EquipmentsModule:AddEquipmentsDataToTweak(e_self)
    for _, data in ipairs(self._config) do
        if data._meta == "special" then
            if e_self.specials[data.id] then
                self:Err("Special Equipment with id '%s' already exists!", data.id)
            else
                data.text_id = data.text_id or ("hud_equipment_"..data.id)
                data.sync_possession = data.sync_possession or true
                e_self.specials[data.id] = table.merge(data.based_on and deep_clone(e_self.specials[data.based_on] or {}) or {}, data)
            end
        end
    end
end

function EquipmentsModule:RegisterHook()
    local first = BeardLib.Utils.XML:GetNode(self._config, "special")
    if first then
        if tweak_data and tweak_data.equipments then
            self:AddEquipmentsDataToTweak(tweak_data.equipments)
        else
            Hooks:PostHook(EquipmentsTweakData, "init", self._mod.Name..'/'..first.id .. "AddEquipmentsData", ClassClbk(self, "AddEquipmentsDataToTweak"))
        end
    end
end