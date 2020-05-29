local orig = CrimeNetGui.check_job_pressed
function CrimeNetGui:check_job_pressed(x,y, ...)
    for _, job in pairs(self._jobs) do
        if job.mouse_over == 1 and job.update_data then
            self:disable_crimenet()
            BeardLib.Utils.Sync:DownloadMap(job.level_name, job.job_key, job.update_data, function(success)
                self:enable_crimenet()
                self._grabbed_map = false
            end)
            return false
        end
    end
    return orig(self, x,y, ...)
end

function CrimeNetGui:change_to_custom_job_gui(job)
	local x = 0
	local num_stars = 0
	local panel = job.side_panel
	local job_name = panel:child("job_name")
	panel:child("contact_name"):set_text(" ")
	panel:child("contact_name"):set_size(0,0)
	panel:child("heat_name"):set_alpha(0)
	if alive(panel) and alive(job_name) then
		job_name:set_text(managers.localization:to_upper_text("custom_map_title", {map = tostring(job.level_name)}))
		self:make_fine_text(job_name)
		job_name:set_x(0)
	end
	local info_name = panel:child("info_name")
	if alive(panel) and alive(info_name) then
		local state = job.state_name or managers.localization:to_upper_text("menu_lobby_server_state_in_lobby")
		info_name:set_text(managers.localization:to_upper_text("custom_map_download_available") .. (state and " / " .. tostring(state) or ""))
		self:make_fine_text(info_name)
		if job.mouse_over ~= 1 then
			info_name:set_righttop(0, job_name:bottom() - 3)
		end
	end
	local difficulty_stars = job.difficulty_id - 2
	local num_difficulties = Global.SKIP_OVERKILL_290 and 5 or 6
	for i = 1, num_difficulties do
		local stars_panel = panel:child("stars_panel")
		stars_panel:clear()
		stars_panel:bitmap({
			texture = "guis/textures/pd2/cn_miniskull",
			x = x,
			w = 12,
			h = 16,
			texture_rect = {0,0,12,16},
			alpha = i > difficulty_stars and 0.5 or 1,
			blend_mode = i > difficulty_stars and "normal" or "add",
			layer = 0,
			color = i > difficulty_stars and Color.black or tweak_data.screen_colors.risk
		})
		stars_panel:set_w(16 * math.min(11, #stars_panel:children()))
		stars_panel:set_h(16)
		x = x + 11
		num_stars = num_stars + 1
	end
	local difficulty_string = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[tweak_data.difficulties[job.difficulty_id]])
	local difficulty_name = panel:child("difficulty_name")
	difficulty_name:set_text(difficulty_string)
	difficulty_name:set_color(difficulty_stars > 0 and tweak_data.screen_colors.risk or tweak_data.screen_colors.text)
	self:make_fine_text(difficulty_name)
	if job.mouse_over ~= 1 then
		difficulty_name:set_righttop(0, info_name:bottom() - 3)
	end
end