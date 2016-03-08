function TextBoxGui:set_text(txt, no_upper, text_format)
	local text = self._panel:child("info_area"):child("scroll_panel"):child("text")
	text:set_text(no_upper and txt or utf8.to_upper(txt or ""))   
 
    
    self:_set_scroll_indicator()
	self:_check_scroll_indicator_states()
end