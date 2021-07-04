BeardLib.Items.NoteBook = BeardLib.Items.NoteBook or class(BeardLib.Items.Menu)
local NoteBook = BeardLib.Items.NoteBook
NoteBook.type_name = "NoteBook"
NoteBook.HYBRID = true

function NoteBook:Init(...)
    self._pages = {}
    NoteBook.super.Init(self, ...)
    self:InitBasicItem()
    self:GrowHeight()
end

function NoteBook:InitBasicItem()
    NoteBook.super.InitBasicItem(self)
    self.arrow_left = self.panel:bitmap({
        name = "arrow_left",
        w = self.title:h() - 4,
        h = self.title:h() - 4,
        alpha = 0.5,
        texture = "guis/textures/menu_ui_icons",
        color = self:GetForeground(),
        y = 2,
        texture_rect = {39, 32, 32, 32},
        layer = 3,
    })
    self.arrow_right = self.panel:bitmap({
        name = "arrow_right",
        w = self.title:h() - 4,
        h = self.title:h() - 4,
        alpha = 0.5,
        texture = "guis/textures/menu_ui_icons",
        color = self:GetForeground(),
        y = 2,
        texture_rect = {67, 32, 32, 32},
        layer = 3,
    })
    self.page_name = self.panel:text({
		name = "page_name",
		align = "right",
		text = "",
		layer = 3,
		color = self:GetForeground(),
		font = self.font,
		font_size = self.font_size or self.size,
		kern = self.kerning
	})
    self.arrow_right:set_right(self.panel:w())
    self.arrow_left:set_right(self.arrow_right:x() - 2)
    self:RePositionPageCtrls()
end

function NoteBook:RePositionPageCtrls()
    if self:title_alive() then
        if alive(self.bg) and alive(self.highlight_bg) then
            self.bg:set_h(self:TextHeight())
            self.highlight_bg:set_h(self:TextHeight())
        end

        if alive(self.arrow_right) then
            local center_y = self.title:center_y()

            self.arrow_right:set_center_y(center_y)
            self.arrow_left:set_center_y(center_y)
        end
    end
end

function NoteBook:SetText(...)
    if NoteBook.super.SetText(self, ...) then
        self:SetScrollPanelSize()
    end
    self:RePositionPageCtrls()
end

function NoteBook:WorkParams(params)
    NoteBook.super.WorkParams(self, params)
    self:WorkParam("page", 1)
    if self.initial_pages then
        for _, page in pairs(self.initial_pages) do
            self:AddPage(page)
        end
    end
end

function NoteBook:AddToPage(item, page)
    local page_data = self._pages[page]
    if page_data then
        table.insert(page_data.items, item)
    end
    self:UpdatePage()
end

function NoteBook:RemoveFromPage(item, page)
    local page_data = self._pages[page]
    if page_data then
        table.delete(page_data.items, item)
        self:UpdatePage()
    end
end

function NoteBook:SetPage(page)
    local page_data = self._pages[page]
    self.page = page
    self:UpdatePage()
    if self.page_changed then
        self.page_changed(page)
    end
end

function NoteBook:GetCurrentPage()
    return self.page or 0
end

function NoteBook:GetPageCount()
    return #self._pages
end

function NoteBook:GetItemPage(item)
    for i, page in pairs(self._pages) do
        for _, page_item in pairs(page.items) do
            if page_item == item then
                return i
            end
        end
    end
end

function NoteBook:AddItemPage(name, item, indx)
    self:AddPage(name)
    self:AddToPage(item, indx or #self._pages)
end

function NoteBook:SetPageName(indx, name)
    local page = self._pages[indx]
    if page then
        page.name = name
    end
    self:UpdatePage()
end

function NoteBook:AddPage(name, indx)
    local page = {name = name, items = {}}
    if indx then
        table.insert(self._pages, indx, page)
    else
        table.insert(self._pages, page)
    end
end

function NoteBook:RemoveAllPages()
    self._pages = {}
    self:UpdatePage()
end

function NoteBook:RemovePageWithItem(item)
    local indx = self:GetItemPage(item)
    if indx then
        table.remove(self._pages, indx)
        self:UpdatePage()
    end
end

function NoteBook:RemovePage(indx)
    table.remove(self._pages, indx)
    self:UpdatePage()
end

function NoteBook:UpdatePage()
    self.page = math.clamp(self.page, 1, #self._pages)
    self.arrow_right:set_alpha(self.page < #self._pages and 1 or 0.5)
    self.arrow_left:set_alpha(self.page > 1 and 1 or 0.5)

    local page_data = self._pages[self.page]
    self.page_name:set_text(page_data and page_data.name or "")
    local x, y, w, h = self.page_name:text_rect()
	self.page_name:set_size(w, h)
    self.page_name:set_right(self.arrow_left:x() - 2)
    self.page_name:set_center_y(self.bg:center_y())

    for i, item in pairs(self._my_items) do
        if item:ParentPanel() == self:ItemsPanel() and (item.visible or item._hidden_by_menu) then --handle only visible items.
            local visible = (page_data and table.contains(page_data.items, item))
            item:SetVisible(visible)
            item._hidden_by_menu = not visible
        end
    end

    self:_AlignItems()
end

function NoteBook:MousePressed(button, x, y)
    if button == Idstring("0") then
        if self.page < #self._pages and self.arrow_right:inside(x,y) then
            self:SetPage(self.page + 1)
            return true
        elseif self.page > 1 and self.arrow_left:inside(x,y) then
            self:SetPage(self.page - 1)
            return true
        end
    end
    return NoteBook.super.MousePressed(self, button, x, y)
end

function NoteBook:MouseInside(x, y)
    return self.highlight_bg:inside(x,y)
end

function NoteBook:MouseMoved(x, y)
    local ret = self:MouseMovedSelfEvent(x, y)
    if not ret then
        ret = self:MouseMovedMenuEvent(x, y)
    end
    return ret
end

function NoteBook:DoHighlight(highlight)
    NoteBook.super.DoHighlight(self, highlight)
    if alive(self.page_name) then
        local foreground = self:GetForeground(highlight)
        if self.animate_colors then
            play_color(self.page_name, foreground)
        else
            self.page_name:set_color(foreground)
        end
    end
end
