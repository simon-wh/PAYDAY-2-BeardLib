local orig_PlayerMovement_save = PlayerMovement.save

function PlayerMovement:save(data)
	orig_PlayerMovement_save(self, data)
	data.movement.outfit = BeardLib.Utils:CleanOutfitString(data.movement.outfit)
end
