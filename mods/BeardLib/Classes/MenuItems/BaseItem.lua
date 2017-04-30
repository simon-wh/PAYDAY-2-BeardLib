BaseItem = BaseItem or class()
function BaseItem:init(params)
	table.merge(self, clone(params))
	self.type_name = self.type_name or "Button"
	local mitem = getmetatable(self)
	function mitem:__tostring() --STOP FUCKING RESETING
		return string.format("[%s][%s] %s", self:alive() and "Alive" or "Dead", tostring(self.type_name), tostring(self.name)) 
	end
	self:Init()
end
function BaseItem:Init() end

function BaseItem:InitBasicItem()
	local offset = math.max(self.color and 2 or 0, self.text_offset)
	self.title = self.panel:text({
		name = "title",
		x = offset,
		w = self.panel:w() - offset,
		h = self.panel:h(),
		align = self.text_align,
		vertical = self.text_vertical,
		wrap = not self.size_by_text,
		word_wrap = not self.size_by_text,
		text = self.text,
		layer = 3,
		color = self.text_color or Color.black,
		font = self.font,
		font_size = self.items_size
	})
	self.bg = self.panel:rect({
		name = "bg",
		color = self.marker_color,
		alpha = self.marker_alpha,
		h = self.type_name == "Group" and self.items_size,
		halign = self.type_name ~= "Group" and "grow",
		valign = self.type_name ~= "Group" and "grow",
		layer = 0
	})
	self.div = self.panel:rect({
		color = self.color,
		visible = not not self.color,
		h = self.items_size,
		w = 2,
	})
	self:SetText(self.text)
end

function BaseItem:TryRendering()
	local p = self.parent_panel
	local visible = false
	if alive(self.panel) then		
	 	visible = p:inside(p:world_x(), self.panel:world_y()) == true or p:inside(p:world_x(), self.panel:world_bottom()) == true
		self.panel:set_visible(visible)
		self.visible = visible
		if self.debug then
			BeardLib:log("Item %s has been set to rendering=%s", tostring(self), tostring(visible))
		end
	end
	return visible
end

--Return Funcs--
function BaseItem:Panel() return self.panel end
function BaseItem:alive() return alive(self.panel) end
function BaseItem:Value() return self.value end
function BaseItem:Enabled() return self.enabled end
function BaseItem:Index() return self.parent:GetIndex(self.name) end
function BaseItem:MouseInside(x, y) return self.panel:inside(x,y) end
function BaseItem:Visible() return self.visible end
function BaseItem:MouseFocused(x, y)
    if not x and not y then
        x,y = managers.mouse_pointer._mouse:world_position()
    end
    local parent = self.override_parent or self.parent
   --local parent_check = (parent.type_name == "MenuUI" or parent:MouseFocused(x,y))
    return self:alive() and self.panel:inside(x,y) and self:Visible()
end

--Add/Set Funcs--
function BaseItem:AddItem(item) table.insert(self._my_items, item) end
function BaseItem:SetCallback(callback) self.callback = callback end
function BaseItem:SetLabel(label) self.label = label end
function BaseItem:SetParam(k,v) self[k] = v end
function BaseItem:SetEnabled(enabled) self.enabled = enabled end

--Position Func--
function BaseItem:Aligned()
	for _, item in pairs(self._my_items) do
		item:Reposition()
	end
end

function BaseItem:Reposition()
	if not self:alive() then
		return
	end
    local t = type(self.position)
    if t == "table" then
        self.panel:set_position(unpack(self.position))
    elseif t == "function" then
        self:position(self)
    elseif t == "string" then
        self:SetPositionByString(self.position)
    end
end

function BaseItem:SetPosition(x,y)
    if type(x) == "number" or type(y) == "number" then
        self.position = {x or self.panel:x(),y or self.panel:y()}
    else
        self.position = x
    end
    self:Reposition()
end

function BaseItem:SetPositionByString(pos)
	if not pos then
		BeardLib:log("[ERROR] Position for item %s in parent %s is nil!", tostring(self.name), tostring(self.parent.name))
		return
	end
    local pos_panel = self.parent_panel
    for _, p in pairs({"center", "bottom", "top", "right", "left"}) do
        if pos:lower():match(p) then
            self.panel["set_world_"..p](self.panel, pos_panel["world_"..p](pos_panel))
        end
    end
end

function BaseItem:SetValue(value, run_callback)
	if run_callback then
		run_callback = value ~= self.value
	end
	self.value = value
	if run_callback then
		self:RunCallback()
	end
end

function BaseItem:MouseCheck(press)
	if not self:alive() or not self.enabled or (press and self.menu._highlighted ~= self) then
		return false
	end
	return not self.divider_type, true
end

function BaseItem:RunCallback(clbk, ...)
	clbk = clbk or self.callback
	if clbk then
		clbk(self.parent, self, ...)
	end
end