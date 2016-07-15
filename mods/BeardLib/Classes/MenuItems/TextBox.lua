TextBox = TextBox or class(Item)

function TextBox:init( parent, params )	
	params.value = params.value or ""   
	self.type = "TextBox"
	self.size_by_text = false
	self.super.init( self, parent, params )
    self.floats = self.floats or 2
    if self.filter == "number" then
    	self.value = tonumber(self.value) or 0
    end
   	TextBoxBase.init(self, self)
end

function TextBox:SetValue(value, run_callback, reset_selection)
	local text = self.panel:child("text")
	text:set_text(value)
	if reset_selection then
		text:set_selection(text:text():len())		
	end
	self:update_caret() 
	self.super.SetValue(self, value, run_callback)
end

function TextBox:MousePressed( button, x, y )
	if not alive(self.panel) then
		return
	end
	if not self.cantype then
		self:SetValue(self.panel:child("text"):text(), true, true)
	end		
	return self.cantype
end

function TextBox:KeyPressed( o, k )		
end

function TextBox:MouseMoved( x, y )
    self.super.MouseMoved(self, x, y)
    if self.cantype and alive(self.panel) then
        self:SetValue(self.panel:child("text"):text())
    end
end

function TextBox:MouseReleased( button, x, y )
    self.super.MouseReleased( self, button, x, y )
end 