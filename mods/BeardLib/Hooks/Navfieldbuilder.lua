function NavFieldBuilder:_create_build_progress_bar(title, num_divistions)
    BeardLib:log("Progress: " .. tostring(title))
end
function NavFieldBuilder:_destroy_progress_bar()
end
function NavFieldBuilder:_update_progress_bar(percent_complete, text)
	BeardLib:log("Progress: " .. tostring(text))
end
function NavFieldBuilder:update(t, dt)
	if self._building then
		self._building.task_clbk(self)
	end
end
