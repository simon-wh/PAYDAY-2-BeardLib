local function make_fine_text(text, keep_w, keep_h)
	local x, y, w, h = text:text_rect()

	text:set_size(keep_w and text:w() or math.ceil(w), keep_h and text:h() or math.ceil(h))
	text:set_position(math.round(text:x()), math.round(text:y()))

	return text
end

local function thousand_sep(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end
  
local default_margin = 10
local cash_icon = "guis/textures/pd2/blackmarket/cash_drop"
local cc_icon = "guis/textures/pd2/ccoin"
local xp_icon = "guis/textures/pd2/blackmarket/xp_drop"

CustomAchievementMenu = CustomAchievementMenu or class()

function CustomAchievementMenu:init()
	if not MenuCallbackHandler then
		Hooks:Add("SetupInitManagers", "PostInitTweakData_CustomAchievementManagerMenu", function()
			self:init()
		end)

		return
	end

	self._menu = MenuUI:new({
		name = "CustomAchievementMenu",
		layer = 1500,
		use_default_close_key = true,
		background_color = Color.white:with_alpha(0.05),
		inherit_values = {
			background_color = Color.transparent,
			scroll_color = Color.white:with_alpha(0.1),
			highlight_color = Color.white:with_alpha(0.1)
		},
		animate_toggle = true
	})

	self._initialized = false
end

function CustomAchievementMenu:_init_background(parent)
	parent:bitmap({
		name = "bg_blur",
		w = parent:w(),
		h = parent:h(),
		texture = "guis/textures/test_blur_df",
		render_template = "VertexColorTexturedBlur3D",
		halign = "scale",
		valign = "scale"
	})

	parent:rect({
		name = "bg",
		color = Color.black,
		alpha = 0.4,
		layer = -1,
		halign = "scale",
		valign = "scale"
	})
end

function CustomAchievementMenu:_init_panels(parent)
	self._header = parent:Menu({scrollbar = false, background_color = Color.black:with_alpha(0.75), h = 32, align_method = "grid"})
	self._account_progression = parent:Menu({
		scrollbar = false, 
		background_color = Color.black:with_alpha(0.75), 
		h = 120, 
		w = parent._panel:w() / 3,
		offset = default_margin,
		position = function(item)
			item:Panel():set_top(self._header:Panel():bottom() + default_margin)
			item:Panel():set_x(default_margin)
		end
	})
	self._package_list = parent:Menu({
		background_color = Color.black:with_alpha(0.75),
		h = parent._panel:h() - self._account_progression:Panel():h() - self._header:Panel():h() - (default_margin * 3),
		w = parent._panel:w() / 3,
		offset = 2,
		align_method = "grid",
		text_vertical = "center",
		position = function(item)
			item:Panel():set_top(self._account_progression:Panel():bottom() + default_margin)
			item:Panel():set_x(default_margin)
		end
	})

	self._achievement_list_header = parent:Menu({
		scrollbar = false,
		background_color = Color.black:with_alpha(0.75),
		h = 90, 
		w = parent._panel:w() - self._account_progression:Panel():w() - (default_margin * 3),
		offset = default_margin,
		position = function(item)
			item:Panel():set_top(self._header:Panel():bottom() + default_margin)
			item:Panel():set_left(self._account_progression:Panel():right() + default_margin)
		end
	})

	self._achievement_panel = parent:Menu({
		scrollbar = false,
		align_method = "grid",
		background_color = Color.black:with_alpha(0.75),
		h = parent._panel:h() - self._achievement_list_header:Panel():h() - self._header:Panel():h() - (default_margin * 3),
		w = self._achievement_list_header:Panel():w(),
		position = function(item)
			item:Panel():set_top(self._achievement_list_header:Panel():bottom() + default_margin)
			item:Panel():set_left(self._achievement_list_header:Panel():left())
		end
	})

	self._package_not_selected_label = self._achievement_panel:Divider({
		text = "Select a package on the left panel to show the achievements related to it.",
		text_vertical = "center",
		text_align = "center",
		position = function(item)
			item:Panel():set_world_center_y(self._achievement_panel:Panel():world_center_y())
		end
	})

	self._achievement_list = self._achievement_panel:Menu({
		h = self._achievement_panel:Panel():h(),
		align_method = "grid",
		w = self._achievement_panel:Panel():w() / 1.6,
		visible = false
	})

	self._achievement_details = parent:Menu({
		scrollbar = false,
		align_method = "grid",
		h = self._achievement_panel:Panel():h(),
		w = self._achievement_panel:Panel():w() - self._achievement_list:Panel():w() - 15,
		visible = false,
		position = function(item)
			item:Panel():set_top(self._achievement_panel:Panel():top() + 5)
			item:Panel():set_right(self._achievement_panel:Panel():right() - 5)
		end
	})
end

function CustomAchievementMenu:_init_header()
	local icon_trophy = self._header:Image({texture = "guis/textures/achievement_trophy_white", h = 30, w = 30, highlight_color = Color.transparent})
	
	self._header:Divider({
		text = managers.localization:text("beardlib_customachievementmenu_title"),
		size_by_text = true,
		size = 24, 
		position = function(item) 
			item:Panel():set_left(icon_trophy:Panel():right()) 
			item:Panel():set_world_center_y(icon_trophy:Panel():world_center_y()) 
		end 
	})

	self._header:Button({
		text = managers.localization:text("beardlib_close"),
		text_align = "right",
		text_vertical = "center",
		position = "RightOffset-x",
		size_by_text = true,
		size = 24,
		foreground = Color("fff"),
		on_callback = ClassClbk(self, "_close")
	})
end

function CustomAchievementMenu:_init_account()
	local panel = self._account_progression
	local steam_avatar = panel:Image({texture = "guis/texture/pd2/none_icon", w = 64, h = 64})
	local steam_name = managers.network.account:username()

	Steam:friend_avatar(2, Steam:userid(), function (texture)
		local avatar = texture or "guis/textures/pd2/none_icon"
		steam_avatar:SetImage(avatar)
	end)

	DelayedCalls:Add( "BeardLib_Recheck_Account_Avatar", 2, function()
		Steam:friend_avatar(2, Steam:userid(), function (texture)
			local avatar = texture or "guis/textures/pd2/none_icon"
			steam_avatar:SetImage(avatar)
		end)
	end)

	local steam_name_text = panel:Divider({
		text = steam_name, 
		position = function(item) 
			item:Panel():set_left(steam_avatar:Panel():right() + default_margin)
			item:Panel():set_top(steam_avatar:Panel():top())
		end,
		size = 22
	})

	local percent_total = "--"

	if CustomAchievementManager:_number_of_achievements() > 0 then
		percent_total = math.floor(CustomAchievementManager:_completed_achievements_total() * 100 / CustomAchievementManager:_number_of_achievements())
	end

	local total_achievements = panel:Divider({
		text = managers.localization:text("beardlib_customachievementmenu_completed_achievements", {completed = CustomAchievementManager:_completed_achievements_total(), total = CustomAchievementManager:_number_of_achievements(), percent = percent_total}),
		foreground = Color("808080"),
		position = function(item) 
			item:Panel():set_left(steam_avatar:Panel():right() + default_margin)
			item:Panel():set_top(steam_name_text:Panel():bottom())
		end
	})

	local total_packages = panel:Divider({
		text = managers.localization:text("beardlib_customachievementmenu_packages_installed", {nbpackages = CustomAchievementManager:_number_of_packages()}),
		foreground = Color("808080"),
		position = function(item) 
			item:Panel():set_left(steam_avatar:Panel():right() + default_margin)
			item:Panel():set_top(total_achievements:Panel():bottom())
		end
	})

	for idx, nb in ipairs(CustomAchievementManager:_get_all_completed_ranks()) do
		local rank_texture = "guis/textures/achievement_trophy_white"
		local rank_icon = panel:Panel():bitmap({
			name = "rank_icon_".. idx,
			texture = rank_texture,
			w = 24,
			h = 24,
			layer = 5,
			color = Color(CustomAchievementManager._ranks[idx].color)
		})

		rank_icon:set_top(total_packages:Panel():bottom() + 5)
		rank_icon:set_left(total_packages:Panel():left())

		if idx > 1 then
			rank_icon:set_left(panel:Panel():child("rank_icon_".. (idx - 1)):left() + 80)
		end

		local rank_amount = panel:Panel():text({
			text = "x".. tostring(nb),
			font = "fonts/font_large_mf",
			font_size = 16,
			layer = 5
		})
		make_fine_text(rank_amount)

		rank_amount:set_left(rank_icon:right() + 5)
		rank_amount:set_world_center_y(rank_icon:world_center_y())
	end
end

function CustomAchievementMenu:_init_packages()
	local panel = self._package_list
	local sorted_packages = {}

	for i, package_id in ipairs(CustomAchievementManager:_fetch_packages()) do
		local pck = CustomAchievementPackage:new(package_id)
		sorted_packages[i] = {id = package_id, name = pck:_get_name() }
	end

	table.sort( sorted_packages, function(a, b)
		return a.name < b.name
	end)

	for _, package_data in pairs(sorted_packages) do
		local package_id = package_data.id
		local package = CustomAchievementPackage:new(package_id)

		local package_icon = panel:Image({
			texture = package:_get_icon(),
			w = 32,
			h = 32,
			highlight_color = Color.transparent
		})

		local package_name = panel:Button({
			--text = package:_get_name(),
			h = 32,
			w = panel:Panel():w() - package_icon:Panel():w() - 100,
			--size = 24,
			--foreground = Color("cccccc"),
			--text_vertical = "center",
			on_callback = ClassClbk(self, "_display_achievements_from_package", package) 
		})

		package_name:Panel():text({
			text = package:_get_name(),
			font = "fonts/font_large_mf",
			color = Color("eeeeee"),
			font_size = 16,
			vertical = "center",    -- Luffy please add "text_vertical" and "text_align" support to buttons, thank
			x = default_margin
		})

		panel:Divider({
			text = package:_get_completed_achievements() .. " / " .. package:_get_total_achievements(),
			text_vertical = "center",
			text_align = "center",
			foreground = Color("808080"),
			h = 32,
			w = 82
		})
	end
end

function CustomAchievementMenu:_display_achievements_from_package(package)
	local panel = self._achievement_list
	panel:ClearItems()
	panel:SetVisible(true)
	self._achievement_details:SetVisible(false)

	local sorted_achievements = {}

	for achievement_id, achievement_data in pairs(package:_fetch_achievements()) do
		local ach = CustomAchievement:new(package:_get_config_of(achievement_id), package._package_id)
		table.insert(sorted_achievements, {id = ach._id, rank = ach:_get_rank_id()})
	end

	table.sort(sorted_achievements, function(a, b)
		return a.rank > b.rank
	end)
   
	for _, achievement_data in pairs(sorted_achievements) do
		local achievement_id = achievement_data.id
		local achievement = CustomAchievement:new(package:_get_config_of(achievement_id), package._package_id)
		local icon_panel

		if achievement:_is_default_icon() then
			icon_panel = panel:Image({
				texture = achievement:_get_icon(),
				h = 48,
				w = 48,
				layer = 1,
				foreground = Color(achievement:_get_rank_color()):with_alpha(0.7),
				highlight_color = Color.transparent
			})
		else
			icon_panel = panel:Image({
				texture = achievement:_get_icon(),
				h = 48,
				w = 48,
				highlight_color = Color.transparent
			})
		end

		local unlocked_checkmark = icon_panel:Panel():bitmap({
			texture = "guis/textures/checkmark",
			w = 48,
			h = 48,
			visible = false,
			layer = 10,
			color = Color.green,
			x = icon_panel:Panel():x(),
			y = icon_panel:Panel():y()
		})

		unlocked_checkmark:set_world_center_y(icon_panel:Panel():world_center_y())
		unlocked_checkmark:set_world_center_x(icon_panel:Panel():world_center_x())

		BoxGuiObject:new(icon_panel:Panel(), {
			sides = {
				1,
				1,
				1,
				1
			}
		})

		local achievement_button = panel:Button({
			h = 48,
			w = 442,
			on_callback = ClassClbk(self, "_display_achievement_details", achievement)
		})

		local achievement_name = achievement_button:Panel():text({
			text = achievement:_get_name(),
			font = "fonts/font_large_mf",
			font_size = 18,
			x = 5,
			y = 5
		})
		make_fine_text(achievement_name)

		local achievement_rank_icon = achievement_button:Panel():bitmap({
			texture = "guis/textures/achievement_trophy_white",
			h = 24,
			w = 24,
			y = 5,
			color = Color(achievement:_get_rank_color())
		})

		achievement_rank_icon:set_left(achievement_button:Panel():right() - 90)

		if achievement:_is_unlocked() then
			local unlocked_achievement_text = achievement_button:Panel():text({
				text = managers.localization:to_upper_text("beardlib_customachievementmenu_unlocked", {time = os.date('%d/%m/%Y @ %H:%M:%S', achievement:_get_unlock_timestamp())}),
				font = "fonts/font_large_mf",
				font_size = 14,
				color = Color.white:with_alpha(0.5),
				x = 5,
				y = 5
			})

			make_fine_text(unlocked_achievement_text)
			unlocked_achievement_text:set_top(achievement_name:bottom() + 2)

			unlocked_checkmark:set_visible(true)
		elseif not achievement:_is_unlocked() and achievement:_has_amount_value() then
			local progress = achievement:_current_amount_value() / achievement:_amount_value()

			local bar = TextProgressBar:new(achievement_button:Panel(), {
				h = 16,
				w = achievement_button:Panel():w(),
				y = achievement_button:Panel():h() - 16,
				back_color = Color(255, 60, 60, 65) / 255,
				layer = 5
			}, {
				font = "fonts/font_medium_mf",
				font_size = 16
			}, progress)
		end
	end

	self:_display_package_header(package)
end

function CustomAchievementMenu:_display_package_header(package)
	local panel = self._achievement_list_header
	local name = package:_get_name()
	local desc = package:_get_desc()
	local icon = package:_get_icon()
	local banner = package:_get_banner()
	local total_achievements = package:_get_total_achievements()
	local completed_achievements = package:_get_completed_achievements()
	local percent_display = total_achievements > 0 and math.floor(completed_achievements * 100 / total_achievements) or '--'

	panel:ClearItems()
	self._package_not_selected_label:SetVisible(false)

	local banner_panel = panel:Divider({
		w = panel:Panel():w(),
		h = panel:Panel():h(),
		offset = 0
	})

	if banner then
		local banner_image = banner_panel:Panel():bitmap({
			texture = banner,
			w = banner_panel:Panel():w(),
			h = banner_panel:Panel():h()
		})

		local banner_top = banner_panel:Panel():bitmap({
			texture = "guis/textures/achievement_banner_topper",
			w = banner_panel:Panel():w(),
			h = banner_panel:Panel():h(),
			color = Color.black,
			layer = 2
		})
	end

	local package_icon = banner_panel:Panel():bitmap({
		texture = icon,
		h = 86,
		w = 86,
		x = 2,
		y = 2,
		layer = 10
	})

	local package_name = banner_panel:Panel():text({
		text = utf8.to_upper(name),
		font = "fonts/font_large_mf",
		font_size = 28,
		x = 10,
		y = 10,
		layer = 5
	})
	make_fine_text(package_name)

	package_name:set_left(package_icon:right() + 20)

	local current_progress = banner_panel:Panel():text({
		text = managers.localization:to_upper_text("beardlib_customachievementmenu_completed_achievements", {completed = completed_achievements, total = total_achievements, percent = percent_display}),
		font = "fonts/font_large_mf",
		font_size = 18,
		color = Color(0.3, 0.3, 0.3),
		layer = 5
	})
	make_fine_text(current_progress)

	current_progress:set_top(package_name:bottom())
	current_progress:set_left(package_name:left())

	local package_desc = banner_panel:Panel():text({
		text = "\"" .. desc .. "\"",
		font = "fonts/font_large_mf",
		font_size = 16,
		layer = 5,
		visible = desc ~= ""
	})
	make_fine_text(package_desc)

	package_desc:set_top(current_progress:bottom() + 14)
	package_desc:set_left(package_name:left())
end

function CustomAchievementMenu:_display_achievement_details(achievement)
	local panel = self._achievement_details
	panel:SetVisible(true)
	panel:ClearItems()

	local achiev_details = {
		name = achievement:_get_name(),
		icon = achievement:_get_icon(),
		desc = achievement:_get_desc(),
		obj = achievement:_get_objective(),
		rank_name = achievement:_get_rank_name(),
		rank_color = achievement:_get_rank_color(),
		is_unlocked = achievement:_is_unlocked()
	}

	local achiev_text = panel:Divider({
		text = achiev_details.name,
		background_color = Color(achiev_details.rank_color):with_alpha(0.5),
		offset = 0,
		size = 20,
		text_align = "center"
	})

	local achiev_icon = panel:Image({
		texture = achiev_details.icon,
		w = 64,
		h = 64,
		offset = 10,
		foreground = achievement:_is_default_icon() and not achievement:_is_hidden() and Color(achiev_details.rank_color) or nil,
		highlight_color = Color.transparent
	})

	local achiev_desc = panel:Button({
		text = achiev_details.desc,
		--foreground = Color(achiev_details.rank_color),
		size = 14,
		w = 207,
		offset = 10,
		highlight_color = Color.transparent
	})

	--[[local achiev_rank = panel:Divider({
		text = utf8.to_upper(achiev_details.rank_name),
		text_align = "center",
		offset = 0,
		background_color = Color(achiev_details.rank_color)
	})--]]

	local achiev_objective_header = panel:Divider({
		text = managers.localization:to_upper_text("beardlib_customachievementmenu_header_objectives"),
		text_align = "center",
		background_color = Color(achiev_details.rank_color):with_alpha(0.5),
		offset = 5
	})

	local achiev_objective_details = panel:Divider({
		text = achiev_details.obj,
		offset = 10
	})

	if not achievement:_is_unlocked() and achievement:_has_amount_value() then
		local achiev_progress_header = panel:Divider({
			text = utf8.to_upper("Progress"),
			text_align = "center",
			background_color = Color(achiev_details.rank_color):with_alpha(0.5),
			offset = 5
		})

		local progress = achievement:_current_amount_value() * 100 / achievement:_amount_value()

		local achiev_progress_details = panel:Divider({
			text = tostring(achievement:_current_amount_value()) .. " / " .. tostring(achievement:_amount_value()) .. " ( " .. math.floor(progress) .. " %)",
			offset = 10
		})
	end

	if achievement:_has_reward() then
		local achiev_rewards_header = panel:Divider({
			text = managers.localization:to_upper_text("beardlib_customachievementmenu_header_rewards"),
			text_align = "center",
			background_color = Color(achiev_details.rank_color):with_alpha(0.5),
			offset = 5
		})

		local achiev_reward_panel = panel:Menu({scrollbar = false, h = 68, w = panel:Panel():w() - 10, align_method = "grid"})

		if achievement:_get_reward_type() == "xp" then
			local reward_icon = achiev_reward_panel:Image({
				texture = xp_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_exp"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:_sanitize_max_rewards(achievement:_get_reward_amount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		
		elseif achievement:_get_reward_type() == "cash" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cash_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_cash"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:_sanitize_max_rewards(achievement:_get_reward_amount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		elseif achievement:_get_reward_type() == "offshore" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cash_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_offshore"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:_sanitize_max_rewards(achievement:_get_reward_amount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		
		elseif achievement:_get_reward_type() == "cc" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cc_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_cc"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:_sanitize_max_rewards(achievement:_get_reward_amount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		end
	end

	if achiev_details.is_unlocked then
		local unlock_header = panel:Divider({
			text = managers.localization:to_upper_text("beardlib_customachievementmenu_header_unlocked"),
			text_align = "center",
			offset = 5,
			background_color = Color.green
		})

		panel:Divider({
			text = managers.localization:text("beardlib_customachievementmenu_header_unlocked_date", {time = os.date('%d/%m/%Y @ %H:%M:%S', achievement:_get_unlock_timestamp())}),
			foreground = Color("aaaaaa"), -- AAAAAAAA
			text_align = "center",
			offset = 10
		})
	end
end

function CustomAchievementMenu:_close()
	self._menu:SetEnabled(false)
end

function CustomAchievementMenu:_show(state)
	self._menu:SetEnabled(state)
	
	if not self._initialized then
		self:_init_background(self._menu._panel)
		self:_init_panels(self._menu)
		self:_init_header()
		self:_init_account()
		self:_init_packages()

		self._initialized = true
	end
end


return CustomAchievementMenu
