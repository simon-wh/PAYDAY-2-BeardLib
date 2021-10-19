DependenciesModule = DependenciesModule or BeardLib:ModuleClass("Dependencies", ModuleBase)

function DependenciesModule:Load(config)
    config = config or self._config
    local missing_dep = false

    for _, dep in ipairs(config) do
        if dep.name then
            local meta = dep._meta:lower()
            local type = dep.type and dep.type:lower() or "blt"
            if meta == "dependency" then
                if type == "mod_overrides" or type == "map" then
                    if not BeardLib.Utils:ModExists(dep.name) then
                        missing_dep = true

                        self:CreateErrorDialog(dep)
                    end
                elseif type == "blt" then
                    if not BeardLib.Utils:ModExists(dep.name) and not self:CheckBLTMod(dep.name) then
                        missing_dep = true

                        self:CreateErrorDialog(dep)
                    end
                else
                    self:Err("Dependency for '%s' has an invalid type: '%s'", tostring(self._mod.mod), tostring(type))
                end
            elseif meta == "dependencies" then
                self:Load(dep)
            end
        else
            self:Err("Dependency for '%s' has no name", tostring(self._mod.mod))
        end
    end

    if missing_dep then
        return false
    end
end

function DependenciesModule:CheckBLTMod(name)
    for _, v in ipairs(BLT.Mods.mods) do
        if v:GetName() == name then
            return true
        end
    end
end

function DependenciesModule:CreateErrorDialog(dep)
    if dep.id and dep.provider then
        self:AddDepDownload(dep)
        self._mod:ModError("The mod is missing a dependency: '%s' \nYou can download it through the Beardlib Mods Manager.", tostring(dep.name))
    else
        self._mod:ModError("The mod is missing a dependency: '%s'", tostring(dep.name))
    end
end

function DependenciesModule:AddDepDownload(dep)
    --Default install directories for different mod types.
    local install_directory = {
        blt = "./mods/",
        mod_overrides = "./assets/mod_overrides/",
        map = "./maps/"
    }

    dep.type = dep.type and dep.type:lower() or "blt"

    local config = {
        _meta = "AssetUpdates",
        id = dep.id,
        provider = dep.provider,
        install_directory = dep.install_directory or install_directory[dep.type],
        custom_name = dep.name,
        dont_delete = true
    }

    self._mod:AddModule(config)
end