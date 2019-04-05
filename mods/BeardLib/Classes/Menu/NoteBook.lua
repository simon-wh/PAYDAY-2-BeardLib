BeardLib.Items.NoteBook = BeardLib.Items.NoteBook or class(BeardLib.Items.Group)
local NoteBook = BeardLib.Items.NoteBook
NoteBook.type_name = "NoteBook"
NoteBook.divider_type = true
function NoteBook:Init(...)
    self._pages = {}
    NoteBook.super.Init(self, ...)
end

function NoteBook:InitBasicItem()
    NoteBook.super.InitBasicItem(self)
    self.arrow_left = self.panel:bitmap({
        name = "arrow_left",
        w = self.title:h() - 4,
        h = self.title:h() - 4,
        alpha = 0.5,
        texture = "guis/textures/menu_ui_icons",
        color = self:GetForeground(highlight),
        y = 2,
        texture_rect = {4, 17, 16, 16},
        layer = 3,
    })
    self.arrow_right = self.panel:bitmap({
        name = "arrow_right",
        w = self.title:h() - 4,
        h = self.title:h() - 4,
        alpha = 0.5,
        texture = "guis/textures/menu_ui_icons",
        color = self:GetForeground(highlight),
        y = 2,
        texture_rect = {42, 2, 16, 16},
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
end

function NoteBook:RePositionToggle()
    NoteBook.super.RePositionToggle(self)
    if alive(self.arrow_right) and alive(self.title) then
        local center_y = self.title:center_y()

        self.arrow_right:set_center_y(center_y)
        self.arrow_left:set_center_y(center_y)
    end
end

function NoteBook:WorkParams(params)
    NoteBook.super.WorkParams(self, params)
    self:WorkParam("page", 1)
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

function NoteBook:AddItemPage(name, item)
    self:AddPage(name)
    self:AddToPage(item, #self._pages)
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

    for i, item in pairs(self._my_items) do
        if item:ParentPanel() == self:ItemsPanel() and (item.visible or item._hidden_by_menu) then --handle only visible items.
            local visible = (page_data and table.contains(page_data.items, item))
            item:SetVisible(visible)
            item._hidden_by_menu = not visible
        end
    end
    
    self:AlignItems()
    self:_SetSize(nil, nil, true)
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

function NoteBook:MouseMoved(x, y)
    return NoteBook.super.MouseMoved(self, x, y)
end