DependenciesModule = DependenciesModule or BeardLib:ModuleClass("Dependencies", ModuleBase)

function DependenciesModule:Load(config)
    config = config or self._config
    local missing_dep = false

    for _, dep in ipairs(config) do
        if dep.mod and dep.type then
            local meta = dep._meta:lower()
            local type = dep.type:lower()
            if meta == "dependency" then
                if type == "beardlib" or type == "map" then
                    if not BeardLib.Utils:ModExists(dep.mod) then
                        missing_dep = true

                        if dep.id and dep.provider then
                            self:AddDepDownload(dep)
                            self._mod:ModError("The mod is missing a dependency: '%s' \nYou can download it through the Beardlib Mods Manager.", tostring(dep.mod))
                        else
                            self._mod:ModError("The mod is missing a dependency: '%s'", tostring(dep.mod))
                        end
                    end
                elseif type == "blt" then
                    if not self:CheckBLTMod(dep.mod) then
                        missing_dep = true

                        if dep.id and dep.provider then
                            self:AddDepDownload(dep)
                            self._mod:ModError("The mod is missing a dependency: '%s' \nYou can download it through the Beardlib Mods Manager.", tostring(dep.mod))
                        else
                            self._mod:ModError("The mod is missing a dependency: '%s'", tostring(dep.mod))
                        end
                    end
                else
                    self:Err("Dependency for '%s' has an invalid type: '%s'", tostring(self._mod.mod), tostring(type))
                end
            elseif meta == "dependencies" then
                self:Load(dep)
            end
        else
            self:Err("Dependency for '%s' has no mod name and/or type", tostring(self._mod.mod))
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

function DependenciesModule:AddDepDownload(dep)
    --Default install directories for different mod types.
    local install_directory = {
        blt = "./mods/",
        beardlib = "./assets/mod_overrides/",
        map = "./maps/"
    }

    local config = {
        _meta = "AssetUpdates",
        id = dep.id,
        provider = dep.provider,
        install_directory = dep.install_directory or install_directory[dep.type],
        custom_name = dep.mod,
        dont_delete = true
    }

    self._mod:AddModule(config)
end