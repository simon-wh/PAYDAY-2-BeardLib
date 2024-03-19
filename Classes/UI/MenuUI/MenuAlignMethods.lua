local Item = BeardLib.Items.Item
local Menu = BeardLib.Items.Menu
Item.align_methods = {
    grid = "AlignItemsGrid",
    normal = "AlignItemsNormal",
    reversed = "AlignItemsReversed",
    reversed_grid = "AlignItemsReversedGrid",
    centered_grid = "AlignItemsCenteredGrid",
    reversed_centered_grid = "AlignItemsReversedCenteredGrid",
    grid_from_right = "AlignItemsGridFromRight",
    grid_from_right_reversed = "AlignItemsGridFromRightReversed",
}

function Item:_AlignItems(menus, no_parent)
    if not alive(self) then
        return
    end
    if self.delay_align_items then
        self.panel:stop()
        self.panel:animate(function()
            wait(0.000001)
            self:AlignItems(menus, no_parent)
        end)
    else
        self:AlignItems(menus, no_parent)
    end
end

function Item:AlignItems(menus, no_parent, override_auto_align)
    if self.align_method == "none" then self:CheckItems() return end
    if not self.menu_type then return end
	if menus then
		for _, item in pairs(self._my_items) do
			if item.menu_type then
				item:AlignItems(true, true)
			end
		end
    end

    local method = self.align_method
    if method and self.align_methods[method] then
        self[self.align_methods[method]](self)
    else
        self:AlignItemsNormal()
    end

    if self.parent.AlignItems and (override_auto_align or self.parent.auto_align) and not no_parent then
		self.parent:AlignItems(nil, nil, override_auto_align)
    end
    self:CheckItems()
end

function Item:AlignItemsPost(max_h, prev_item)
	local additional = (self.last_y_offset or (prev_item and prev_item:Offset()[2] or 0))
	max_h = max_h + additional -- self:TextHeight() + additional
	self:UpdateCanvas(max_h)
    if prev_item and not self.auto_height and prev_item.stretch_to_bottom and prev_item.SetSize then
        prev_item:SetSize(nil, self:Height() - self:TextHeight() - prev_item:Y() - additional)
        prev_item:AlignItems(false, true)
    end
end

function Item:RepositionItem(item, last_positioned_item, prev_item, max_h, max_right)
	local repos = item:Reposition(last_positioned_item, prev_item)
	if repos then
		last_positioned_item = item
	end
    local count = (not repos and not item.ignore_align) or item.count_as_aligned
    local panel = item:Panel()

    if count then
        prev_item = item
        if max_right then
            max_right = math.max(max_right, panel:right())
        end
	end
	if max_h and count or item.count_height then
		max_h = math.max(max_h, panel:bottom())
    end

    item:DelayLifted()

	return last_positioned_item, prev_item, max_h, max_right
end

function Item:DelayLifted()
    if self._hidden_by_delay then
        self._hidden_by_delay = false
        self:TryRendering()
    end
end

function Item:AlignItemsNormal(reversed)
    if not self:alive() then
        return
    end
    local max_h, prev_item, last_positioned_item = 0, nil, nil
    local function align(item)
        if item then
            if item:_Visible() then
                if not item.ignore_align then
                    local offset = item:Offset()
                    local panel = item:Panel()
                    panel:set_x(offset[1])
                    if alive(prev_item) then
                        panel:set_world_y(prev_item:Panel():world_bottom() + offset[2])
                    else
                        panel:set_y(offset[2])
                    end
                end
                last_positioned_item, prev_item, max_h = self:RepositionItem(item, last_positioned_item, prev_item, max_h)
            else
                item:DelayLifted()
            end
        end
    end

    local items = self._my_items
    if reversed then
        for i=#items, 1, -1 do
            align(items[i])
        end
    else
        for i=1, #items do
            align(items[i])
        end
    end

    self:AlignItemsPost(max_h, prev_item)
end

function Item:AlignItemsReversed()
    self:AlignItemsNormal(true)
end

function Item:AlignItemsGrid(reversed)
    if not self:alive() then
        return
    end
    local items_w = self:ItemsWidth()
    local prev_item, last_positioned_item
    local max_h, max_right, max_y = 0, 0, 0

    local function align(item)
        if item then
            if item:_Visible() then
                if not item.ignore_align then
                    local panel = item:Panel()
                    local offset = item:Offset()
                    if (panel:w() + (max_right + offset[1]) - items_w) > 0.001 then
                        max_y = max_h
                        max_right = 0
                    end
                    panel:set_position(max_right + offset[1], max_y + offset[2])
                end
                last_positioned_item, prev_item, max_h, max_right = self:RepositionItem(item, last_positioned_item, prev_item, max_h, max_right)
            else
                item:DelayLifted()
            end
        end
    end

    local items = self._my_items
    if reversed then
        for i=#items, 1, -1 do
            align(items[i])
        end
    else
        for i=1, #items do
            align(items[i])
        end
    end

    self:AlignItemsPost(max_h, prev_item)
end

function Item:AlignItemsReversedGrid()
    self:AlignItemsGrid(true)
end

function Item:AlignItemsCenteredGrid(reversed)
    if not self:alive() then
        return
    end
    local prev_item, last_positioned_item
    local max_h, max_right, max_y = 0, 0, 0
    local items_w = self:ItemsWidth()
    local center = items_w / 2
    local current_row = {}

    local function centerify()
        if #current_row == 0 then return end
        local centerify = center - (max_right / 2)
        for _, row_item in pairs(current_row) do
            if not row_item.repos then
                row_item.panel:move(centerify)
            end
        end
    end

    local function align(item)
        if item then
            if item:_Visible() then
                local panel = item:Panel()
                if not item.ignore_align then
                    local offset = item:Offset()
                    if (prev_item and prev_item.alone_in_row) or (panel:w() + (max_right + offset[1]) - items_w) > 0.001 then
                        centerify()
                        current_row = {}
                        max_y = max_h
                        max_right = 0
                    end
                    if #current_row == 0 then
                        panel:set_position(max_right, max_y + offset[2])
                    else
                        panel:set_position(max_right + offset[1], max_y + offset[2])
                    end
                end

                local repos = item:Reposition(last_positioned_item, prev_item)
                item:DelayLifted()

                if repos then
                    last_positioned_item = item
                end
                local was_aligned = (not repos and not item.ignore_align) or item.count_as_aligned
                if was_aligned or item.count_height then
                    if was_aligned then
                        prev_item = item
                        max_right = math.max(max_right, panel:right())
                    end
                    table.insert(current_row, {panel = panel, repos = repos})
                    max_h = math.max(max_h, panel:bottom())
                end
            else
                item:DelayLifted()
            end
        end
    end

    local items = self._my_items
    if reversed then
        for i=#items, 1, -1 do
            align(items[i])
        end
    else
        for i=1, #items do
            align(items[i])
        end
    end

    centerify()
    self:AlignItemsPost(max_h, prev_item)
end

function Item:AlignItemsReversedCenteredGrid()
    self:AlignItemsCenteredGrid(true)
end

function Item:AlignItemsGridFromRight(reversed, dbg)
    if not self:alive() then
        return
    end
    local items_w = self:ItemsWidth()
    local prev_item
    local max_h, max_right, max_y = 0, items_w, 0

    local function align(item)
        if item then
            if item:_Visible() then
                if not item.ignore_align then
                    local panel = item:Panel()
                    local offset = item:Offset()
                    if ((max_right - offset[1]) - panel:w()) < -0.001 then
                       max_y = max_h
                       max_right = items_w
                    end
                    panel:set_righttop(max_right - offset[1], max_y + offset[2])
                end
                local count = not item.ignore_align or item.count_as_aligned
                local panel = item:Panel()
                item:DelayLifted()

                if count then
                    prev_item = item
                    max_right = math.min(max_right, panel:left())
                end
                if count or item.count_height then
                    max_h = math.max(max_h, panel:bottom())
                end
            else
                item:DelayLifted()
            end
        end
    end

    local items = self._my_items
    if reversed then
        for i=#items, 1, -1 do
            align(items[i])
        end
    else
        for i=1, #items do
            align(items[i])
        end
    end

    self:AlignItemsPost(max_h, prev_item)
end

function Item:AlignItemsGridFromRightReversed()
    self:AlignItemsGridFromRight(true)
end