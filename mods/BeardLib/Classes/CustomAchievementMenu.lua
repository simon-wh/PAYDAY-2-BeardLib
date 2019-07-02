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

	local accent_color = BeardLib.Options:GetValue("MenuColor")

	self._menu = MenuUI:new({
		name = "CustomAchievementMenu",
		animate_colors = true,
		layer = 1500,
		use_default_close_key = true,
		background_blur = true,
		auto_foreground = true,
		accent_color = accent_color,
		inherit_values = {
			background_color = Color.transparent,
			scroll_color = Color.white:with_alpha(0.1),
			highlight_color = Color.white:with_alpha(0.1)
		},
		animate_toggle = true
	})

	self._initialized = false
end

function CustomAchievementMenu:InitPanels(parent)
	self._header = parent:Grid({background_color = self._menu.accent_color, h = 32})
	self._account_progression = parent:Grid({
		background_color = Color.black:with_alpha(0.75), 
		h = 120, 
		w = parent._panel:w() / 3,
		foreground = Color("808080"),
		offset = default_margin,
		position = function(item)
			if alive(self._header) then
				item:SetXY(default_margin, self._header:Bottom() + default_margin)
			end
		end
	})
	self._package_list = parent:GridMenu({
		background_color = Color.black:with_alpha(0.75),
		h = parent._panel:h() - self._account_progression:ItemsHeight() - self._header:ItemsHeight() - (default_margin * 3),
		w = parent._panel:w() / 3,
		offset = 2,
		position = function(item)
			if alive(self._account_progression) then
				item:SetXY(default_margin, self._account_progression:Bottom() + default_margin)
			end
		end
	})

	self._achievement_list_header = parent:Holder({
		background_color = Color.black:with_alpha(0.75),
		h = 90, 
		w = parent._panel:w() - self._account_progression:Panel():w() - (default_margin * 3),
		offset = default_margin,
		position = function(item)
			if alive(self._account_progression) then
				item:SetXY(self._account_progression:Right() + default_margin, self._header:Bottom() + default_margin)
			end
		end
	})

	self._achievement_panel = parent:Grid({
		background_color = Color.black:with_alpha(0.75),
		h = parent._panel:h() - self._achievement_list_header:Panel():h() - self._header:Panel():h() - (default_margin * 3),
		w = self._achievement_list_header:Panel():w(),
		position = function(item)
			if alive(self._achievement_list_header) then
				item:SetXY(self._achievement_list_header:X(), self._achievement_list_header:Bottom() + default_margin)
			end
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

	self._achievement_list = self._achievement_panel:GridMenu({
		h = self._achievement_panel:Panel():h(),
		w = self._achievement_panel:Panel():w() / 1.6,
		visible = false
	})

	self._achievement_details = parent:Grid({
		h = self._achievement_panel:Panel():h(),
		w = self._achievement_panel:Panel():w() - self._achievement_list:Panel():w() - 15,
		visible = false,
		position = function(item)
			if alive(self._achievement_panel)then
				item:SetRightTop(self._achievement_panel:Right() - 5, self._achievement_panel:Y() + 5)
			end
		end
	})
end

function CustomAchievementMenu:InitHeader()
	local icon_trophy = self._header:Image({texture = "guis/textures/achievement_trophy_white", h = 30, w = 30, highlight_color = Color.transparent})
	
	self._header:Divider({
		text = managers.localization:text("beardlib_customachievementmenu_title"),
		size_by_text = true,
		size = 24,
		count_as_aligned = true,
		position = "Centery"
	})

	self._header:Button({
		text = managers.localization:text("beardlib_close"),
		text_align = "right",
		position = "RightOffset-x",
		size_by_text = true,
		size = 24,
		foreground = Color("fff"),
		on_callback = ClassClbk(self, "Close")
	})
end

function CustomAchievementMenu:InitAccount()
	local panel = self._account_progression
	local steam_avatar = panel:Image({texture = "guis/texture/pd2/none_icon", img_color = Color.white, w = 64, h = 64})
	local stats = panel:Grid({
		name = "Stats",
		inherit_values = {offset = {0, 3}},
		w = panel:ItemsWidth() - steam_avatar:OuterWidth() - panel:OffsetX()*2
	})
	local steam_name = managers.network.account:username()

	Steam:friend_avatar(2, Steam:userid(), function (texture)
		local avatar = texture or "guis/textures/pd2/none_icon"
		steam_avatar:SetImage(avatar)
	end)

	DelayedCalls:Add("BeardLib_Recheck_Account_Avatar", 2, function()
		Steam:friend_avatar(2, Steam:userid(), function (texture)
			local avatar = texture or "guis/textures/pd2/none_icon"
			if alive(steam_avatar) then
				steam_avatar:SetImage(avatar)
			end
		end)
	end)

	local steam_name_text = stats:Divider({
		name = "SteamName",
		text = steam_name,
		size = 22
	})

	local percent_total = "--"

	if CustomAchievementManager:NumberOfAchievements() > 0 then
		percent_total = math.floor(CustomAchievementManager:CompletedAchievementsTotal() * 100 / CustomAchievementManager:NumberOfAchievements())
	end

	local total_achievements = stats:QuickText(managers.localization:text("beardlib_customachievementmenu_completed_achievements", {
		completed = CustomAchievementManager:CompletedAchievementsTotal(), total = CustomAchievementManager:NumberOfAchievements(), percent = percent_total
	}))

	local total_packages = stats:QuickText(managers.localization:text("beardlib_customachievementmenu_packages_installed", {
		nbpackages = CustomAchievementManager:NumberOfPackages()
	}))

	local rank_texture = "guis/textures/achievement_trophy_white"
	for idx, nb in ipairs(CustomAchievementManager:GetAllCompletedRanks()) do
		local rank_icon = stats:Image({
			name = "rank_icon_".. idx,
			texture = rank_texture,
			w = 24,
			h = 24,
			layer = 5,
			img_color = Color(CustomAchievementManager._ranks[idx].color)
		})

	--	rank_icon:set_position(total_packages:Panel():x(), total_packages:Panel():bottom() + 5)

		--if idx > 1 then
		--	rank_icon:set_x(stats:GetItem("rank_icon_".. (idx - 1)):x() + 80)
		--end

		local rank_amount = stats:Divider({
			text = "x".. tostring(nb),
			size_by_text = true,
			count_as_aligned = true,
			position = function(item)
				item:SetCenterY(rank_icon:CenterY())
			end,
			font = "fonts/font_large_mf",
			font_size = 16
		})
	end
end

function CustomAchievementMenu:InitPackages()
	local panel = self._package_list
	local sorted_packages = {}

	for i, package_id in ipairs(CustomAchievementManager:FetchPackages()) do
		local pck = CustomAchievementPackage:new(package_id)
		sorted_packages[i] = {id = package_id, name = pck:GetName()}
	end

	table.sort(sorted_packages, function(a, b)
		return a.name < b.name
	end)

	for _, package_data in pairs(sorted_packages) do
		local package_id = package_data.id
		local package = CustomAchievementPackage:new(package_id)

		local package_icon = panel:Image({
			texture = package:GetIcon(),
			w = 32,
			h = 32,
			highlight_color = Color.transparent
		})

		local package_name = panel:Button({
			text = package:GetName(),
			h = 32,
			w = panel:Panel():w() - package_icon:Panel():w() - 100,
			foreground = Color("eeeeee"),
			on_callback = ClassClbk(self, "DisplayAchievementsFromPackage", package) 
		})

		panel:Divider({
			text = package:GetCompletedAchievements() .. " / " .. package:GetTotalAchievements(),
			text_align = "center",
			foreground = Color("808080"),
			h = 32,
			w = 82
		})
	end
end

function CustomAchievementMenu:DisplayAchievementsFromPackage(package)
	local panel = self._achievement_list
	panel:ClearItems()
	panel:SetVisible(true)
	self._achievement_details:SetVisible(false)

	local sorted_achievements = {}

	for achievement_id, achievement_data in pairs(package:FetchAchievements()) do
		local ach = CustomAchievement:new(package:GetConfigOf(achievement_id), package._package_id)
		table.insert(sorted_achievements, {id = ach._id, rank = ach:GetRankID()})
	end

	table.sort(sorted_achievements, function(a, b)
		return a.rank > b.rank
	end)
   
	for _, achievement_data in pairs(sorted_achievements) do
		local achievement_id = achievement_data.id
		local achievement = CustomAchievement:new(package:GetConfigOf(achievement_id), package._package_id)
		local icon_panel

		if achievement:IsDefaultIcon() then
			icon_panel = panel:Image({
				texture = achievement:GetIcon(),
				h = 48,
				w = 48,
				layer = 1,
				foreground = Color(achievement:GetRankColor()):with_alpha(0.7),
				highlight_color = Color.transparent
			})
		else
			icon_panel = panel:Image({
				texture = achievement:GetIcon(),
				h = 48,
				w = 48,
				highlight_color = Color.transparent
			})
		end

		local unlocked_checkmark = icon_panel:Image({
			texture = "guis/textures/checkmark",
			w = 48,
			h = 48,
			offset = 0,
			layer = 10,
			visible = false,
			img_color = Color.green,
		})

		local achievement_button = panel:Button({
			h = 48,
			w = 442,
			text = achievement:GetName(),
			on_callback = ClassClbk(self, "DisplayAchievementDetails", achievement)
		})

		achievement_button:Image({
			img_color = Color(achievement:GetRankColor()),
			texture = "guis/textures/achievement_trophy_white",
			position = "RightCentery",
			h = 24,
			w = 24,
		})
 
		if achievement:IsUnlocked() then
			local unlocked_achievement_text = achievement_button:Divider({
				text = managers.localization:to_upper_text("beardlib_customachievementmenu_unlocked", {time = os.date('%d/%m/%Y @ %H:%M:%S', achievement:GetUnlockTimestamp())}),
				font_size = 14,
				size_by_text = true,
				position = function(item)
					if alive(achievement_name) then
						item:SetXY(achievement_name:LeftBottom())
					end
				end,
				foreground = Color.white:with_alpha(0.5)
			})
			
			unlocked_checkmark:SetVisible(true)
		elseif not achievement:IsUnlocked() and achievement:HasAmountValue() then
			local progress = achievement:CurrentAmountValue() / achievement:AmountValue()

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

	self:DisplayPackageHeader(package)
end

function CustomAchievementMenu:DisplayPackageHeader(package)
	local panel = self._achievement_list_header
	local name = package:GetName()
	local desc = package:GetDesc()
	local icon = package:GetIcon()
	local banner = package:GetBanner()
	local total_achievements = package:GetTotalAchievements()
	local completed_achievements = package:GetCompletedAchievements()
	local percent_display = total_achievements > 0 and math.floor(completed_achievements * 100 / total_achievements) or '--'

	panel:ClearItems()
	self._package_not_selected_label:SetVisible(false)

	local banner_panel = panel:Grid({
		name = "banner_panel",
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

	banner_panel:Image({
		name = "package_icon",
		texture = icon,
		h = 86,
		w = 86,
		offset = 2
	})

	local package_name = banner_panel:FitDivider({
		name = "package_name",
		text = utf8.to_upper(name),
		font_size = 28
	})

	local current_progress = banner_panel:FitDivider({
		name = "current_progress",
		text = managers.localization:to_upper_text("beardlib_customachievementmenu_completed_achievements", {completed = completed_achievements, total = total_achievements, percent = percent_display}),
		position = function(item)
			if alive(package_name) then
				item:SetXY(package_name:LeftBottom())
			end
		end,
		font_size = 18,
		foreground = Color(0.3, 0.3, 0.3),
	})

	local package_desc = banner_panel:FitDivider({
		name = "package_desc",
		text = "\"" .. desc .. "\"",
		position = function(item)
			if alive(current_progress) then
				item:SetXY(current_progress:LeftBottom())
				item:Move(0, 14)
			end
		end,
		font_size = 16,
		visible = desc ~= ""
	})
end

function CustomAchievementMenu:DisplayAchievementDetails(achievement)
	local panel = self._achievement_details
	panel:SetVisible(true)
	panel:ClearItems()

	local achiev_details = {
		name = achievement:GetName(),
		icon = achievement:GetIcon(),
		desc = achievement:GetDesc(),
		obj = achievement:GetObjective(),
		rank_name = achievement:GetRankName(),
		rank_color = achievement:GetRankColor(),
		is_unlocked = achievement:IsUnlocked()
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
		foreground = achievement:IsDefaultIcon() and not achievement:IsHidden() and Color(achiev_details.rank_color) or nil,
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

	if not achievement:IsUnlocked() and achievement:HasAmountValue() then
		local achiev_progress_header = panel:Divider({
			text = utf8.to_upper("Progress"),
			text_align = "center",
			background_color = Color(achiev_details.rank_color):with_alpha(0.5),
			offset = 5
		})

		local progress = achievement:CurrentAmountValue() * 100 / achievement:AmountValue()

		local achiev_progress_details = panel:Divider({
			text = tostring(achievement:CurrentAmountValue()) .. " / " .. tostring(achievement:AmountValue()) .. " ( " .. math.floor(progress) .. " %)",
			offset = 10
		})
	end

	if achievement:HasReward() then
		local achiev_rewards_header = panel:Divider({
			text = managers.localization:to_upper_text("beardlib_customachievementmenu_header_rewards"),
			text_align = "center",
			background_color = Color(achiev_details.rank_color):with_alpha(0.5),
			offset = 5
		})

		local achiev_reward_panel = panel:Grid({h = 68, w = panel:Panel():w() - 10})

		if achievement:GetRewardType() == "xp" then
			local reward_icon = achiev_reward_panel:Image({
				texture = xp_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_exp"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:SanitizeMaxRewards(achievement:GetRewardAmount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		
		elseif achievement:GetRewardType() == "cash" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cash_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_cash"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:SanitizeMaxRewards(achievement:GetRewardAmount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		elseif achievement:GetRewardType() == "offshore" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cash_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_offshore"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:SanitizeMaxRewards(achievement:GetRewardAmount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
		
		elseif achievement:GetRewardType() == "cc" then
			local reward_icon = achiev_reward_panel:Image({
				texture = cc_icon,
				h = 64,
				w = 64
			})

			local reward_title = achiev_reward_panel:Divider({text = managers.localization:to_upper_text("beardlib_customachievementmenu_reward_cc"), size_by_text = true})
			achiev_reward_panel:Divider({text = "+ ".. thousand_sep(achievement:SanitizeMaxRewards(achievement:GetRewardAmount())), size_by_text = true, position = function(item) item:Panel():set_top(reward_title:Panel():bottom() + 20) item:Panel():set_left(reward_title:Panel():left()) end})
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
			text = managers.localization:text("beardlib_customachievementmenu_header_unlocked_date", {time = os.date('%d/%m/%Y @ %H:%M:%S', achievement:GetUnlockTimestamp())}),
			foreground = Color("aaaaaa"), -- AAAAAAAA
			text_align = "center",
			offset = 10
		})
	end
end

function CustomAchievementMenu:Close()
	self._menu:SetEnabled(false)
end

function CustomAchievementMenu:SetEnabled(state)
	self._menu:SetEnabled(state)
	
	if not self._initialized then
		self:InitPanels(self._menu)
		self:InitHeader()
		self:InitAccount()
		self:InitPackages()

		self._initialized = true
	end
end


return CustomAchievementMenu
