ContactModule = ContactModule or class(ItemModuleBase)
ContactModule.type_name = "contact"
ContactModule._loose = true

function ContactModule:AddContactData(narr_self)
    if not self._config.id then
        self:log("[ERROR] Contact does not contain a definition for id!")
        return
    end

    local data = {
        name_id = self._config.name_id,
        description_id = self._config.desc_id,
        package = self._config.package,
        assets_gui = self._config.assets_gui and self._config.assets_gui:id()
    }
    if self._config.merge_data then
        table.merge(data, BeardLib.Utils:RemoveMetas(self._config.merge_data, true))
    end
    narr_self.contacts[self._config.id] = data
end

function ContactModule:RegisterHook()
    if tweak_data and tweak_data.narrative then
        self:AddContactData(tweak_data.narrative)
    else
        Hooks:PostHook(NarrativeTweakData, "init", self._config.id .. "AddContactData", ClassClbk(self, "AddContactData"))
    end
end

BeardLib:RegisterModule(ContactModule.type_name, ContactModule)