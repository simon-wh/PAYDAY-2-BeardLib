--Includes hooks and related functions.

--Removes a post hook using an object and ID, this is unlike RemovePostHook which uses ID only;
--the problem with the normal function is that you might have hooks with the same name so it'll remove ALL of them.

function Hooks:RemovePostHookWithObject(object, id)
    local hooks = self._function_hooks and self._function_hooks[object] or self._posthooks[object]
    if not hooks then
        BeardLib:log("[Error] No post hooks for object '%s' while trying to remove id '%s'", tostring(object), tostring(id))
        return
    end
    for _, func in pairs(hooks) do
        local tbl = func.overrides.post or func.overrides
        for override_i, override in ipairs(tbl) do
            if override and override.id == id then
                table.remove(tbl, override_i)
            end
        end
    end
end

--Same as RemovePostHookWithObject but for pre hooks.

function Hooks:RemovePreHookWithObject(object, id)
    local hooks = self._function_hooks and self._function_hooks[object] or self._prehooks[object]
    if not hooks then
        BeardLib:log("[Error] No pre hooks for object '%s' while trying to remove id '%s'", tostring(object), tostring(id))
        return
    end
    for func_i, func in pairs(hooks) do
        local tbl = func.overrides.pre or func.overrides
        for override_i, override in ipairs(tbl) do
            if override and override.id == id then
                table.remove(tbl, override_i)
            end
        end
    end
end

--Returns a quick class to create post/pre hooks with a predefined name so you don't have to retype it.

function Hooks:QuickClass(hooks_name)
    local clss = {name = hooks_name}
    function clss:Post(object, func_name, hook_func)
        Hooks:PostHook(object, func_name, hooks_name..func_name, hook_func)
    end
    function clss:Pre(object, func_name, hook_func)
        Hooks:PreHook(object, func_name, hooks_name.."_pre_"..func_name, hook_func)
    end
    function clss:RemovePost(object, func_name)
        Hooks:RemovePostHookWithObject(object, hooks_name..func_name)
    end
    function clss:RemovePre(object, func_name)
        Hooks:RemovePreHookWithObject(object, func_name)
    end
    return clss
end

--An even lazier version of the Hooks:QuickClass, good for large classes so you don't have to repeat the class name.

function Hooks:LazyClass(object, hooks_name)
    local clss = {name = hooks_name, object = object}
    function clss:SetClass(object)
        self.object = object
    end
    function clss:Post(func_name, hook_func)
        Hooks:PostHook(clss.object, func_name, hooks_name..func_name, hook_func)
    end
    function clss:Pre(func_name, hook_func)
        Hooks:PreHook(clss.object, func_name, hooks_name.."_pre_"..func_name, hook_func)
    end
    function clss:RemovePost(func_name)
        Hooks:RemovePostHookWithObject(clss.object, hooks_name..func_name)
    end
    function clss:RemovePre(func_name)
        Hooks:RemovePreHookWithObject(clss.object, func_name)
    end
    return clss
end

local list_add = table.list_add
function SimpleClbk(f, a, b, c, ...)
    if not f then
        return function() end
    end
    if a ~= nil then
        if c ~= nil then
            local args = {...}
            return function(...) return f(a, b, c, unpack(list_add(args, ...))) end
        elseif b ~= nil then
            return function(...) return f(a, b, ...) end
        else
            return function(...) return f(a, ...) end
        end
    else
        return function(...) return f(...) end
    end
end

function SafeClbk(...)
    local f = SimpleClbk(...)
    return function(...)
        local success, ret = pcall(f)
        if not success then
            BeardLib:log("[Safe Callback Error] %s", tostring(ret and ret.code or ""))
            return nil
        end
        return ret
    end
end

function SafeClassClbk(...)
    local f = ClassClbk(...)
    return function(...)
        local success, ret = pcall(f)
        if not success then
            BeardLib:log("[Safe Callback Error] %s", tostring(ret and ret.code or ""))
            return nil
        end
        return ret
    end
end

function ClassClbk(clss, func, a, b, c, ...)
    local f = clss[func]
    if not f then
        BeardLib:log("[Callback Error] Function named %s was not found in the given class", tostring(func))
        return function() end
    end
    if a ~= nil then
        if c ~= nil then
            local args = {...}
            return function(...) return f(clss, a, b, c, unpack(list_add(args, ...))) end
        elseif b ~= nil then
            return function(...) return f(clss, a, b, ...) end
        else
            return function(...) return f(clss, a, ...) end
        end
    else
        return function(...) return f(clss, ...) end
    end
end