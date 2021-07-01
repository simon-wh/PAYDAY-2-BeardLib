local SyncUtils = BeardLib.Utils.Sync
Hooks:PostHook(BaseNetworkSession, "create_local_peer", "BeardLibExtraOutfitCreateLocal", function(self, load_outfit)
	if load_outfit then
		self._local_peer:set_extra_outfit_string_beardlib(SyncUtils:ExtraOutfitString())
	end
end)