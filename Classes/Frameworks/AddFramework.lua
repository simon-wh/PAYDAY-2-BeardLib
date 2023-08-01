AddFramework = AddFramework or BeardLib:Class(FrameworkBase)
AddFramework.type_name = "Add"
AddFramework._directory = BeardLib.config.mod_override_dir

function AddFramework:init()
    -- Deprecated, try not to use.
    if self.type_name == AddFramework.type_name then
        BeardLib.Frameworks.add = self
        BeardLib.managers.AddFramework = self
    end

    AddFramework.super.init(self)
end