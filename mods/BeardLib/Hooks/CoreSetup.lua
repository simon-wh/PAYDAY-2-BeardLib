core:module("CoreSetup")
--CloneClass(CoreSetup)

log("Core Setup")
--[[function CoreSetup.update(self, t, dt)
	self.orig.update(self, t, dt)
	log("update")
end]]--