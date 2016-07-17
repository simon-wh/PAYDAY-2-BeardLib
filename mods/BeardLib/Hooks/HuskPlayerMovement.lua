local orig_HuskPlayerMovement_save = HuskPlayerMovement.save

function HuskPlayerMovement:save(data)
    orig_HuskPlayerMovement_save(self, data)
	data.movement.outfit = BeardLib.Utils:CleanOutfitString(data.movement.outfit)
end
