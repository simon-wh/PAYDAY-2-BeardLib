TextBox = TextBox or class(Item)

function TextBox:init( menu, params )
	self.super.init( self, menu, params )
	local text = params.panel:text({
	    name = "text",
	    text = params.value,
	    valign = "center",
	    align = "left",
	    vertical = "center",
        w = (params.panel:w() / 1.5) - 4,
		wrap = true,
		word_wrap = true,        
	    h = 16,
	    layer = 8,
	    color = Color.black,
	    font = "fonts/font_medium_mf",
	    font_size = 16
	}) 	
	text:set_selection(text:text():len())
	local bg = params.panel:bitmap({
        name = "textbg",
        y = 4,
        x = -2,
        w = params.panel:w() / 1.5,
        h = 16,
        layer = 5,
        color = Color(0.5, 0.5, 0.5),
    })		
    local caret = params.panel:rect({
        name = "caret",
        w = 2,
        h = 16,
       	alpha = 0,
        layer = 9,
    })			
    text:enter_text(callback(self, self, "enter_text"))	
    caret:animate(callback(self, self, "blink"))
    bg:set_world_right(params.panel:right() - 4)
    text:set_center(bg:center())
end

function TextBox:SetValue(value)
	local text = self.panel:child("text")
	text:set_text(value)
	text:set_selection(text:text():len())
	self:update_caret()	
	self.super.SetValue(self, value)
end
 
function TextBox:blink( caret )
	local t = 2
	while true do
		local dt = coroutine.yield()
 		t = t - dt	
 		local cv = math.sin( t * 200 ) 
		local col = math.lerp(0, 1, cv)
		caret:set_alpha(self.cantype and math.lerp(0, 1, cv) or 0)
 	end
end
function TextBox:key_hold( text, k )
  	while self.menu.key_pressed == k and self.menu._highlighted == self do
		local text = self.panel:child("text")			
		local s, e = text:selection()
		local n = utf8.len(text:text())
		if Input:keyboard():down(Idstring("left ctrl")) then
	    	if Input:keyboard():down(Idstring("a")) then
	    		text:set_selection(0, text:text():len())
	    	elseif Input:keyboard():down(Idstring("c")) then
	    		Application:set_clipboard(tostring(text:selected_text())) 
	    	elseif Input:keyboard():down(Idstring("v")) then
				text:replace_text(tostring(Application:get_clipboard()))
	    	end
	    elseif Input:keyboard():down(Idstring("left shift")) then
	  	    if Input:keyboard():down(Idstring("left")) then
				text:set_selection(s - 1, e)
			elseif Input:keyboard():down(Idstring("right")) then
				text:set_selection(s, e + 1)  	
			end
	    else	
		    if k == Idstring("backspace") then		
		    	if not (utf8.len(text:text()) < 1) then
					if s == e and s > 0 then
						text:set_selection(s - 1, e)
					end
					text:replace_text("")      
				end    	
		    elseif k == Idstring("left") then
				if s < e then
					text:set_selection(s, s)
				elseif s > 0 then
					text:set_selection(s - 1, s - 1)
				end
			elseif k == Idstring("right") then
				if s < e then
					text:set_selection(e, e)
				elseif s < n then
					text:set_selection(s + 1, s + 1)
				end	
			else
				self.menu.key_pressed = nil
		    end	
	    end		
		self:update_caret()	
	    wait(0.1)
  	end
end
function TextBox:enter_text( text, s )
	if self.menu._highlighted == self and self.cantype and not Input:keyboard():down(Idstring("left ctrl")) then
		text:replace_text(s)	
		self:update_caret()	
	end
	
end
function TextBox:mouse_pressed( o, button, x, y )
	self.super.mouse_pressed(self, o, button, x, y)
	self.cantype = self.panel:inside(x,y) and button == Idstring("0")
	self:update_caret()	
	if not self.cantype then
		self:SetValue(self.panel:child("text"):text())
	end	
end

function TextBox:key_press( o, k )	
	local text = self.panel:child("text")			
 	text:animate(callback(self, self, "key_hold"), k)
	self:update_caret()	
end
 
function TextBox:update_caret()		
	local text = self.panel:child("text")
	local lines = math.max(1,text:number_of_lines())
	self.panel:set_h( 24 * lines )
	self.panel:child("textbg"):set_h((24 / 1.5) * lines)
	self.panel:child("text"):set_h((24 / 1.5) * lines)
 
	self.panel:child("text"):set_center(self.panel:child("textbg"):center())
 	self.parent:AlignItems()
	
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()
	if s == 0 and e == 0 then
		x = text:world_x()
		y = text:world_y()
	end
	self.panel:child("caret"):set_world_position(x, y + 2)
	self.panel:child("caret"):set_visible(self.cantype)
end

function TextBox:mouse_moved( o, x, y )
	self.super.mouse_moved(self, o, x, y)
	self.cantype = self.panel:inside(x,y) and self.cantype or false		
	self.panel:child("caret"):set_visible(self.cantype)
	self:update_caret()
	if not self.cantype then
		self:SetValue(self.panel:child("text"):text())
	end
end
