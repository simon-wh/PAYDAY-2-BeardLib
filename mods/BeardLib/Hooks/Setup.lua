Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(ply)
    managers.dlc:give_missing_package()
end)
