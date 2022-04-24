core:import("CoreMissionScriptElement")
ElementRelativeTeleport = ElementRelativeTeleport or class(CoreMissionScriptElement.MissionScriptElement)

-- AIGroupType Element
-- Creator: Cpone

function ElementRelativeTeleport:client_on_executed(...)
	self:on_executed(...)
end

function ElementRelativeTeleport:on_executed(instigator, ...)
	if not self._values.enabled then
		return
	end

	if self._values.target and #self._values.target > 1 then
		return
	end

	ElementRelativeTeleport.super.on_executed(self, instigator, ...)

	if instigator and alive(instigator) then
		local instigator_position = instigator:position()
		local instigator_rotation = instigator:rotation()

		local current_position = self._values.position
		local current_rotation = self._values.rotation

		local target = self:get_mission_element(self._values.target[1])
		if not target then return end

		local target_position = target:value("position")
		local target_rotation = target:value("rotation")

		local rotation_change = Rotation:rotation_difference(current_rotation, target_rotation)

		local instigator_relative_position = instigator_position - current_position
		mvector3.rotate_with(instigator_relative_position, rotation_change)

		local instigator_velocity = instigator:velocity()
		mvector3.rotate_with(instigator_velocity, rotation_change)

		local new_pos = target_position + instigator_relative_position
		local new_rot = rotation_change * instigator_rotation

		instigator:warp_to(new_rot, new_pos)
		instigator:set_velocity(instigator_velocity)

		local is_player = instigator == managers.player:player_unit()
		if is_player then
			local movement = instigator:movement()
			local current_state = movement:current_state()
			local camera_base = current_state._camera_unit:base()

			local camera_rotation = rotation_change * Rotation(camera_base._camera_properties.spin, camera_base._camera_properties.pitch, 0)
			camera_base._camera_properties.spin = camera_rotation:yaw()
			camera_base._camera_properties.pitch = camera_rotation:pitch()

			if current_state._state_data.enter_air_pos_z then
				current_state._state_data.enter_air_pos_z = current_state._state_data.enter_air_pos_z + (target_position.z - current_position.z)
			end

			local saved_player_velocity = mvector3.copy(current_state._last_velocity_xy)
			mvector3.rotate_with(saved_player_velocity, rotation_change)

			instigator:warp_to(new_rot, new_pos)
			instigator:set_velocity(instigator_velocity)

			if saved_player_velocity then
				mvector3.set(current_state._last_velocity_xy, saved_player_velocity)
				instigator:mover():set_velocity(current_state._last_velocity_xy)
			end

			if _G.IS_VR then
				movement:set_ghost_position(pos)
			end
		else
			instigator:warp_to(new_rot, new_pos)
			instigator:set_velocity(instigator_velocity)
		end
	end
end
