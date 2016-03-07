EnvironmentEditorHandler = EnvironmentEditorHandler or class()

function EnvironmentEditorHandler:init(path)
    self._path = path
    self._default_data = {}
    self._current_data = {}
    self._apply_data = {}
end

function EnvironmentEditorHandler:AddValue(path_key, value, path)
    self._default_data[path_key] = {value = value, path = path}
end

function EnvironmentEditorHandler:GetCurrentValue(path_key)
    return self._current_data[path_key] and self._current_data[path_key].value or self._default_data[path_key] and self._default_data[path_key].value or nil
end

function EnvironmentEditorHandler:GetDefaultValue(path_key)
    return self._default_data[path_key] and self._default_data[path_key].value
end

function EnvironmentEditorHandler:SetValue(path_key, value, path, editor, vtype)
    self._apply_data[path_key] = {value = value, path = path, vtype = vtype, editor = editor}
end

function EnvironmentEditorHandler:GetEditorValues()
    local default = self._default_data
    local current = self._current_data
    
    return table.merge(default, current)
end