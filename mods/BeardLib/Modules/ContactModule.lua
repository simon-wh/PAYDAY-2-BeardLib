ContactModule = ContactModule or class(ModuleBase)

ContactModule.type_name = "contact"
ContactModule._loose = true

function ContactModule:init(core_mod, config)
    self.super.init(self, core_mod, config)
end

function ContactModule:RegisterHook()
    Hooks:PostHook(NarrativeTweakData, "init", self._config.id .. "AddContactData", function(narr_self)
        narr_self.contacts[self._config.id] = {
            name_id = self._config.name_id,
            description_id = self._config.desc_id,
            package = self._config.package,
            assets_gui = self._config.assets_gui and self._config.assets_gui:id()
        }
    end)
end

return ContactModule
