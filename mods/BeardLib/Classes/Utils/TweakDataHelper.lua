TweakDataHelper = TweakDataHelper or {}
local tdh = TweakDataHelper

tdh._storage = {}
tdh._overwrite_storage = {}
tdh._callbacks = {}

function tdh:ModifyTweak(data, ...)
    local dest_tbl = tweak_data or self._storage
    local path = {...}
    local key = table.remove(path)
    for _, k in pairs(path) do
        dest_tbl[k] = dest_tbl[k] or {}
        dest_tbl = dest_tbl[k]
	end

    if type(dest_tbl[key]) == "table" then
        table.add_merge(dest_tbl[key], data)
    else
        dest_tbl[key] = data
    end
end

function tdh:OverwriteTweak(data, ...)
    table.insert(self._overwrite_storage, {path = {...}, data = data})
    if tweak_data then
        self:ApplyOverwrites(tweak_data)
    end
end

function tdh:ModifyTweakFunc(tbl_name, clbk)
    self._callbacks[tbl_name] = self._callbacks[tbl_name] or {}
    table.insert(self._callbacks[tbl_name], clbk)
end

--Takes tweak_main and tweak_data_tbl for cases where this is being called from a tweak init function as it wont have been inserted into the tweak_data main table yet.
function tdh:Apply(tweak_main, tweak_data_tbl, tbl_name)
    tweak_data_tbl = tweak_data_tbl or (tbl_name and tweak_main[tbl_name]) or tweak_main or tweak_data
    table.add_merge(tweak_data_tbl, (tbl_name and self._storage[tbl_name] or self._storage) or {})
    self:ApplyOverwrites(tweak_data_tbl)
    if tbl_name then
        self._storage[tbl_name] = nil
        if self.callback[tbl_name] then
            for _, func in pairs(self.callbacks[tbl_name]) do
                func(tweak_data_tbl or tweak_main[tbl_name], tweak_main)
            end
            self.callbacks[tbl_name] = nil
        end
    else
        self._storage = {}
        for k, sub_tbl in pairs(self._callbacks) do
            for _, func in pairs(sub_tbl) do
                func(tweak_main[k], tweak_main)
            end
        end
    end
end

function tdh:ApplyOverwrites(tweak_data_tbl)
    for _, overwrite in pairs(self._overwrite_storage) do
        local current = tweak_data_tbl or tweak_data
        for i, key in pairs(overwrite.path) do
            current[key] = current[key] or {}
            if #overwrite.path == i then
                current[key] = overwrite.data
            else
                current = current[key]
            end
        end
    end
    self._overwrite_storage = nil
end