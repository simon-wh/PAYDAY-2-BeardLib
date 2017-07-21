Hooks:PostHook(Setup, "init_managers", "BeardLibAddMissingDLCPackages", function(ply)
	if managers.dlc.give_missing_package then
    	managers.dlc:give_missing_package()
    end
    Hooks:Call("SetupInitManagers")
end)