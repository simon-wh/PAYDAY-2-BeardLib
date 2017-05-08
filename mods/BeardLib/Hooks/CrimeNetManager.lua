local orig = CrimeNetGui.check_job_pressed
function CrimeNetGui:check_job_pressed(...)
    local is_custom
    local params = {...}
    for id, job in pairs(self._jobs) do
		local function done_map_download()
			BeardLib.managers.MapFramework:Load()
			BeardLib.managers.MapFramework:RegisterHooks()
			for id, new_job in pairs(self._jobs) do
				if new_job.update_key == job.update_key then
					new_job.mouse_over = 1
				end
			end
			managers.job:_check_add_heat_to_jobs()
			managers.crimenet:find_online_games(Global.game_settings.search_friends_only)
			--orig(self, unpack(params)) pls
		end
        if job.mouse_over == 1 and job.update_key then
        	is_custom = true
            QuickMenu:new("Custom Heist Alert", "You need to download the heist before joining, begin download?",
                {[1] = {text = "Yes", callback = function()
                	local provider = ModAssetsModule._providers.modworkshop --temporarily will support only mws
				    dohttpreq(ModCore:GetRealFilePath(provider.download_info_url, tostring(job.update_key)), function(data, id)
						local ret, d_data = pcall(function() return json.decode(data) end)
						if ret then			
						    local download_url = ModCore:GetRealFilePath(provider.download_api_url, d_data[tostring(job.update_key)])
						    BeardLib:log("Downloading map from url: %s", download_url)
						    managers.menu:show_download_progress(tostring(job.level_name) .. " " .. managers.localization:text("mod_assets_title"))
						    dohttpreq(download_url, callback(ModAssetsModule, ModAssetsModule, "StoreDownloadedAssets", {install_directory = "Maps", done_callback = done_map_download}), LuaModUpdates.UpdateDownloadDialog)
						else
							BeardLib:log("Failed to parse the data received from Modworkshop(Invalid map?)")
						end
					end)
                end
            },[2] = {text = "No", is_cancel_button = true}}, true)
            return true
        end
    end
    if not is_custom then
        return orig(self, ...)
    end
end

local orig_job_gui = CrimeNetGui._create_job_gui
function CrimeNetGui:_create_job_gui(data, ...)
	local job = orig_job_gui(self, data, ...)
	if data.custom then
		local x = 0
		local num_stars = 0
		local panel = job.side_panel
		local job_name = panel:child("job_name")
		if alive(panel) and alive(job_name) then
			job_name:set_text(tostring(data.level_name))
			self:make_fine_text(job_name)
		end
		local info_name = panel:child("info_name")
		if alive(panel) and alive(info_name) then
			info_name:set_text(utf8.to_upper("Download Available"))
			self:make_fine_text(info_name)
			info_name:set_righttop(0, job_name:bottom() - 3)
		end
		local difficulty_stars = data.difficulty_id - 2
		local num_difficulties = Global.SKIP_OVERKILL_290 and 5 or 6
		for i = 1, num_difficulties do
			local stars_panel = panel:child("stars_panel")
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
		job_num = #tweak_data.narrative:job_chain(data.job_id)
		local total_payout, base_payout, risk_payout = managers.money:get_contract_money_by_stars(0, difficulty_stars, job_num, data.job_id)
		job_cash = managers.experience:cash_string(math.round(total_payout))
		local difficulty_string = managers.localization:to_upper_text(tweak_data.difficulty_name_ids[tweak_data.difficulties[data.difficulty_id]])
		local difficulty_name = panel:child("difficulty_name")
		difficulty_name:set_text(difficulty_string)
		difficulty_name:set_color(difficulty_stars > 0 and tweak_data.screen_colors.risk or tweak_data.screen_colors.text)
		self:make_fine_text(difficulty_name)
		difficulty_name:set_righttop(0, info_name:bottom() - 3)
	end
	return job
end