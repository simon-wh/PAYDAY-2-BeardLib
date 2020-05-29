--ElementEnvironment--
--Created by Luffy

core:import("CoreMissionScriptElement")
ElementEnvironment = ElementEnvironment or class(CoreMissionScriptElement.MissionScriptElement)

function ElementEnvironment:init(...)
    ElementEnvironment.super.init(self, ...)
end

function ElementEnvironment:on_script_activated()
    self._mission_script:add_save_state_cb(self._id)
end

function ElementEnvironment:client_on_executed(...)
    self:on_executed(...)
end

function ElementEnvironment:on_executed(instigator)
    if not self._values.enabled then
        return
    end

    local color_gradings = {
        "color_off",
        "color_payday",
        "color_heat",
        "color_nice",
        "color_sin",
        "color_bhd",
        "color_xgen",
        "color_xxxgen",
        "color_matrix"
    }

    if self._values.color_grading and self._values.color_grading ~= "none" then
        if self._values.random then
            managers.environment_controller:set_default_color_grading(color_gradings[math.random(1, #color_gradings)])
        else
            managers.environment_controller:set_default_color_grading(self._values.color_grading)
        end
    end

    if self._values.chromatic_amount and self._values.chromatic_amount ~= -1 then
        if self._values.random then
            managers.environment_controller:set_base_chromatic_amount(math.random(self._values.min_amount or 0, self._values.max_amount or 200))
        else
            managers.environment_controller:set_base_chromatic_amount(self._values.chromatic_amount)
        end
    end

    if self._values.contrast and self._values.contrast ~= -1 then
        if self._values.random then
            managers.environment_controller:set_base_contrast(math.random(self._values.min_amount or 0, self._values.max_amount or 10))
        else
            managers.environment_controller:set_base_contrast(self._values.contrast)
        end
    end

    if self._values.brightness and self._values.brightness ~= -1 then
        if self._values.random then
            Application:set_brightness(math.random(self._values.min_amount or 0, self._values.max_amount or 5))
        else
            Application:set_brightness(self._values.brightness)
        end
    end

    managers.environment_controller:refresh_render_settings()

    ElementEnvironment.super.on_executed(self, instigator)
end

function ElementEnvironment:save(data)
    data.save_me = true
    data.enabled = self._values.enabled
end

function ElementEnvironment:load(data)
    self:set_enabled(data.enabled)
end
