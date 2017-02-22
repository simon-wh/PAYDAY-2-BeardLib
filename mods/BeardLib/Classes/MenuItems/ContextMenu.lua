ContextMenu = ContextMenu or class()

function ContextMenu:init(parent, layer)
    self._parent = parent
    self.parent = parent.parent
    self.menu = parent.menu
    self.panel = self.menu._panel:panel({
        name = parent.name.."list",
        w = parent.panel:w(),
        layer = layer,
        visible = false,
        halign = "left",
        align = "left"
    })
    self.panel:rect({
        name = "bg",
        color = (self.parent.background_color or Color.white) / 1.2,
        layer = -1,
        halign = "grow",
        valign = "grow",
    })
    if self._parent.searchbox then
        self._textbox = TextBoxBase:new(self, {
            text_color = self.parent.background_color and self.parent.text_color or Color.black,
            panel = self.panel,
            align = "center",
            lines = 1,
            items_size = parent.items_size,
            update_text = callback(self, self, "update_search"),
        })
    end
    self._scroll = ScrollablePanel:new(self.panel, "ItemsPanel", {layer = 4, padding = 0.0001, scroll_width = parent.scrollbar == false and 0 or 8, hide_shade = true})
    self.items_panel = self._scroll:canvas()   
    
    self:update_search()
end

function ContextMenu:CreateItems()
    self.items_panel:clear()
    local bg = self.panel:child("bg")
    for k, text in pairs(self.found_items) do
        if type(text) == "table" then
            text = text.text
        end
        self.items_panel:text({
            name = "item"..k,
            text = self._parent.localized_items and managers.localization:text(tostring(text)) or tostring(text),
            align = "center",
            h = 12,
            y = (k - 1) * 14,
            color = self.parent.background_color and self.parent.text_color or Color.black,
            font = "fonts/font_medium_mf",
            font_size = 12
        })
    end
    if self.menu._openlist == self then
        self:reposition()
    end
end

function ContextMenu:hide()
    if alive(self.panel) then
        self.panel:hide()
    end
    self.menu._openlist = nil
end

function ContextMenu:reposition()    
    local bottom_h = (self.menu._panel:world_bottom() - self._parent.panel:world_bottom()) 
    local top_h = (self._parent.panel:world_y() - self.menu._panel:world_y()) 
    local items_h = (#self.found_items * 14) + (self._parent.searchbox and self._parent.items_size or 0)
    local normal_pos = items_h <= bottom_h or bottom_h >= top_h
    if (normal_pos and items_h > bottom_h) or (not normal_pos and items_h > top_h) then
        self.panel:set_h(math.min(bottom_h, top_h))
    else
        self.panel:set_h(items_h)
    end
    self.panel:set_world_x(self._parent.panel:world_x())
    if normal_pos then
        self.panel:set_world_y(self._parent.panel:world_bottom())
    else
        self.panel:set_world_bottom(self._parent.panel:world_y())
    end
    self._scroll:panel():set_y(self._parent.items_size) 
    self._scroll:set_size(self.panel:w(), self.panel:h() - (self._parent.items_size or 0))
    self._scroll:panel():child("scroll_up_indicator_arrow"):set_top(6 - self._scroll:padding())
    self._scroll:panel():child("scroll_down_indicator_arrow"):set_bottom(self._scroll:panel():h() - 6 - self._scroll:padding())

    self._scroll:update_canvas_size()    
end

function ContextMenu:show()    
    if self.menu._openlist == self then
        self:hide()
        return
    end
    self:reposition()
    self.panel:show()

    self.menu._openlist = self
end

function ContextMenu:MousePressed(button, x, y)        
    if self._textbox then
        self._textbox:MousePressed(button, x, y)
    end
    if self.panel:inside(x,y) then
        if button == Idstring("mouse wheel down") or button == Idstring("mouse wheel up") then
            if self._scroll:scroll(x, y, button == Idstring("mouse wheel up") and 1 or -1) then
                self:MouseMoved(x, y)
                return true
            end
        end
        if button == Idstring("0") then
            if self._scroll:mouse_pressed(button, x, y) then return true end
            for k, item in pairs(self._parent.items) do
                if alive(self.items_panel:child("item"..k)) and self.items_panel:child("item"..k):inside(x,y) then
                    if self._parent.ContextMenuCallback then
                        self._parent:ContextMenuCallback(item)
                    else
                        if item.callback then self._parent:RunCallback(item.callback, item) end            
                    end        
                    self:hide()
                    return true
                end
            end
        end
        return true
    elseif button == Idstring("0") or button == Idstring("1") then
        self:hide()
        return true
    end
end

function ContextMenu:KeyPressed(o, k)
    if self._textbox then
        self._textbox:KeyPressed(o, k)
    end
    if not alive(self.panel) then
        return
    end
    if self.menu._openlist and k == Idstring("esc") then
        self.menu._openlist:hide()
    end
end

function ContextMenu:update_search()
    local text = self._textbox and self._textbox.panel:child("text"):text() or ""
    self.found_items = {}
    for _, v in pairs(self._parent.items) do
        if type(v) == "table" then
            v = v.text
        end
        if text == "" or tostring(v):lower():match(tostring(text)) then
            if #self.found_items <= 200 then
                table.insert(self.found_items, v)
            else
                break
            end
        end
    end
    self:CreateItems()
end

function ContextMenu:MouseMoved(x, y)
    if self._textbox then
        self._textbox:MouseMoved(x, y)
    end
    local _, pointer = self._scroll:mouse_moved(nil, x, y) 
    if pointer then
        managers.mouse_pointer:set_pointer_image(pointer)
        return true
    else
        managers.mouse_pointer:set_pointer_image("arrow")
    end     
end

function ContextMenu:MouseReleased(button, x, y)
    if self._textbox then
        self._textbox:MouseReleased(button, x, y)
    end
    self._scroll:mouse_released(button, x, y)
end
