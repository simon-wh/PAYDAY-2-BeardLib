Table = Table or class(Item)

function Table:init( menu, params )   
    params.items = params.items or {}
    self.super.init( self, menu, params )    
    local table_panel = params.panel:panel({
        name = "table",
        y = 4,
        x = -2,
        w = params.panel:w() / 1.4,
        layer = 5,
    })
    local add_btn
    if params.add ~= false then
        add_btn = params.panel:text({
            name = "add_btn",
            text = "+",
            w = 16,
            h = 16,
            layer = 6,
            align = "center",        
            color = params.text_color or Color.black,
            font = "fonts/font_medium_mf",
            font_size = 16
        })    
    end
    local remove_btn
    if params.remove ~= false then
        remove_btn = params.panel:text({
            name = "remove_btn",
            text = "-",
            w = 16,
            h = 16,
            align = "center",
            layer = 6,
            color = params.text_color or Color.black,
            font = "fonts/font_medium_mf",
            font_size = 16
        })
    end
    local caret = params.panel:rect({
        name = "caret",
        w = 1,
        h = 14,
        alpha = 0,
        layer = 9,
    })
    caret:animate(callback(self, TextBox, "blink"))
    if add_btn then
        add_btn:set_world_right(params.panel:right())
        if remove_btn then
            remove_btn:set_right(add_btn:left())
        end
    else
        if remove_btn then
            remove_btn:set_world_right(params.panel:right())
        end
    end
    table_panel:set_world_right(params.panel:right() - 4)    
    table_panel:set_top(add_btn and add_btn:bottom() or remove_btn and remove_btn:bottom() or 0)
    self:SetValue(self.items)
end 
function Table:Add(k, v)
    local table_panel = self.panel:child("table")
    local key_text = self.panel:child("key_text")
    local value_text = self.panel:child("value_text")
    self.items[k] = v
    local table_item = table_panel:panel({
        name = "item_" .. k,
        h = 18,
        color = self.text_color or Color.black,
    })
    local key = table_item:text({
        name = "key",
        text = tostring(k),
        w = table_panel:w() / 2,
        x = 4,
        layer = 1,        
        color = self.text_color or Color.black,
        font = "fonts/font_medium_mf",
        font_size = 16
    })
    if type(v) == "boolean" then
        local value = table_item:bitmap({
            name = "value",
            w = table_item:h() -2,
            h = table_item:h() -2,            
            layer = 1,
            color = self.text_color or Color.black,
            texture = "guis/textures/menu_tickbox",
            texture_rect = v == true and {24,0,24,24} or {0,0,24,24},
        })
        value:set_left(key:right())  
    else
        local value = table_item:text({
            name = "value",
            text = tostring(v),
            w = table_panel:w() / 2,
            layer = 1,
            color = self.text_color or Color.black,
            font = "fonts/font_medium_mf",
            font_size = 16
        })
        value:enter_text(callback(self, self, "enter_text")) 
        value:set_left(key:right())  
    end 
    local table_item_bg = table_item:rect({
        name = "bg",
        color = Color(0.6, 0.6, 0.6),
        layer = 0,
    })    
    self:Align()
end

function Table:Remove(k)
    if self.items[k] then
        local table_panel = self.panel:child("table")
        table_panel:remove(table_panel:child("item_" .. k))    
        self.items[k] = nil
        self:Align()
    end
end
function Table:Align()
    local table_panel = self.panel:child("table")
    local h = 18
    for i, child in pairs(table_panel:children()) do
        child:set_y((18 * (i - 1)))
        h = h + child:h()
    end    
    self.panel:set_h(h + 8)
    table_panel:set_h(h)   
    self.parent:AlignItems()
end

function Table:Clear()
    local table_panel = self.panel:child("table")
    table_panel:clear()
    self.items = {}
end

function Table:enter_text( text, s )
    if self.menu._menu_closed then
        return
    end    
    if self.menu._highlighted == self and self._highlighted and self._highlighted.panel == text:parent() and self.cantype and not Input:keyboard():down(Idstring("left ctrl")) then
        if type(self.items[self._highlighted.k]) == "number" and tonumber(s) == nil then
            return
        end
        text:replace_text(s)
        self:update_caret()
        self:Set(self._highlighted.k, text:text())       
        if self.callback then
          self.callback(self.parent, self)
        end
    end
end
function Table:Set(k, v)
    if type(self.items[k]) == "number" then
        self.items[k] = tonumber(v)
    else
        self.items[k] = v
    end
    local value = self.panel:child("table"):child("item_" .. k):child("value")
    if type(v) == "boolean" then
        if v == true then
            managers.menu_component:post_event("box_tick")
            value:set_texture_rect(24,0,24,24)
        else
            managers.menu_component:post_event("box_untick")
            value:set_texture_rect(0,0,24,24)
        end
    else
        value:set_text(v)
        value:set_selection(value:text():len())
    end
end
function Table:SetValue(items)    
    self:Clear()
    for k,v in pairs(items) do
        if type(v) ~= "userdata" then
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    if type(v2) ~= "table" and type(v2) ~= "userdata" then
                        self:Add(k .. ":" .. k2, v2)
                    end
                end
            else
                self:Add(k,v)               
            end
        end
    end
end
function Table:mouse_pressed( o, button, x, y )
    if button == Idstring("0") then
        if self._highlighted and self._highlighted.panel:inside(x,y) then
            local value = self.items[self._highlighted.k]
            if type(value) == "boolean" then
                self:Set(self._highlighted.k, not value)
                if self.callback then
                    self.callback(self.parent, self)
                end          
                return true   
            else
                self.cantype = self._highlighted.panel:inside(x,y)
                self:update_caret()
                return self.cantype 
            end
        end        
        if self.panel:child("add_btn") and self.panel:child("add_btn"):inside(x,y) then
            self:show_add_value_dialog()
            return true
        end    
        if self.panel:child("remove_btn") and self.panel:child("remove_btn"):inside(x,y) then
            self:show_remove_value_dialog()
            return true        
        end
    end
end

function Table:show_add_value_dialog(menu, item)
    local items = {             
        {
            name = "key",
            text = "Key:",
            value = menu and menu:GetItem("key").value or "",
            type = "TextBox",
        },      
        {
            name = "value",
            text = "Value:", 
            type = "TextBox",           
        },
        {
            name = "type",
            text = "Type:",
            items = {"string", "number", "boolean"},
            callback = callback(self, self, "show_add_value_dialog"),
            value = item and item.value or 1,
            type = "ComboBox",
        }
    }
    if item and item.value == 3 then  
        items[2] = {
            name = "value",
            text = "Value:",      
            value = true,
            type = "Toggle",
        }
    end
    BeardLib.managers.Dialog:show({
        title = "Add new value",
        callback = callback(self, self, "AddValueCallback"),
        items = items,
        yes = "Add",
        no = "Close",
    })
end
function Table:show_remove_value_dialog(menu, item)
    local items = {}
    for k,v in pairs(self.items) do
        table.insert(items , {
            name = k,
            text = k .. "[" .. type(v) .. "]",
            value = false,
            type = "Toggle",
        })
    end
    BeardLib.managers.Dialog:show({
        title = "Remove values",
        callback = callback(self, self, "RemoveValueCallback"),
        items = items,
        yes = "Delete",
        no = "Close",      
    })
end

function Table:AddValueCallback(items)
    if not self.items[items[1].value] then
        self.items[items[1].value] = items[2].value
        self:Add(items[1].value,items[2].value)
        if self.callback then
            self.callback(self.parent, self)
        end                  
    end
end
function Table:RemoveValueCallback(items)
    for _, item in pairs(items) do
        if item.value == true then
            self:Remove(item.name)
        end
    end
    if self.callback then
        self.callback(self.parent, self)
    end                          
end
function Table:update_caret()
    if self.cantype then
        local text = self._highlighted.panel:child("value")
        if text.selection then
            local s, e = text:selection()
            local x, y, w, h = text:selection_rect()
            if s == 0 and e == 0 then
                x = text:world_x()
                y = text:world_y()
            end
            self.panel:child("caret"):set_world_position(x, y + 2)
        end
    end
    self.panel:child("caret"):set_visible(self.cantype)
end

function Table:key_press( o, k )
    if self._highlighted and self._highlighted.panel:child("value").text then
        self._highlighted.panel:child("value"):animate(callback(self, TextBox, "key_hold"), k)
        self:update_caret()
    end
end

function Table:mouse_moved( o, x, y )
    self.super.mouse_moved(self, o, x, y, false)   
    self.cantype = self._highlighted and self._highlighted.panel:inside(x,y) and self.cantype or false
    for k,v in pairs(self.items) do
        local table_item = self.panel:child("table"):child("item_" .. k)
        if table_item then
            if table_item:inside(x,y) then
                table_item:child("bg"):set_color(Color(0, 0.5, 1))
                self._highlighted = {panel = table_item, k = k}
            else
                table_item:child("bg"):set_color(Color(0.6, 0.6, 0.6))
            end
            if not self.cantype and type(v) ~= "boolean" and type(v) ~= "table" then
                self:Set(k, table_item:child("value"):text())
            end
        end
    end
    self._highlighted = self._highlighted and (alive(self._highlighted.panel) and self._highlighted.panel:inside(x,y)) and self._highlighted or nil    
    self:update_caret()
end
