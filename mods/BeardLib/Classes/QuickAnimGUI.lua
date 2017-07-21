QuickAnim = QuickAnim or {}
function QuickAnim:Work(o, ...)
    local tbl = {...}
    local stop
    if not alive(o) then
        return
    end
    if o:script().animating then
        if table.equals(o:script().animating, tbl) then
            return
        else
            stop = true
        end
    end
    local anim_tbl = {}
    local opt = {
        speed = 1,
        stop = false,
        wait = false,
        callback = false,
        after = false
    }
    local done 
    for i=1, #tbl, 2 do
        local k = tbl[i]
        local sticky
        if string.begins(k, "sticky_") then
            k = k:gsub("sticky_", "")
            sticky = true
        end
        local v = tbl[i + 1]
        if opt[k] ~= nil then
            opt[k] = v or opt[k]
        else
            table.insert(anim_tbl, {key = k, value = v, sticky = sticky})
        end       
    end            
    if anim_tbl.stop or stop == true then
        o:stop()
        anim_tbl.stop = nil
    end
    o:script().animating = tbl
    local abs = math.abs
    local step = math.step
    o:animate(function(o)
        local speeds = {}
        if opt.wait then wait(opt.wait) end
        while not done do
            for i, anim in pairs(anim_tbl) do
                local k = anim.key
                local v = anim.value
                local sticky = anim.sticky
                if not alive(o) then
                    if opt.callback then opt.callback() end
                    return
                end

                local cv = o[k](o)
                speeds[k] = speeds[k] or (abs(cv - v) * opt.speed)
                speeds[k] = speeds[k] < 1 and 1 or speeds[k]
                o["set_"..k](o, sticky and v or step(cv, v, self:dt() * speeds[k]))
                if opt.after then opt.after(o) end
                if i == #anim_tbl and alive(o) then
                    done = true
                    for _, anim in pairs(anim_tbl) do
                        done = done and o[anim.key](o) == anim.value
                    end
                end
            end
        end
        if alive(o) then
            for _, anim in pairs(anim_tbl) do 
                o["set_"..anim.key](o, anim.value)    
            end
            o:script().animating = nil
        end
        if opt.callback then opt.callback(o) end
    end)
end

function QuickAnim:LightWork(o, nv, cv, nv, speed)
    o:animate(function(o)
        o:script().animating = {}
        local done
        local speed = speed and (abs(cv - v) * opt.speed) or 1
        speed = speed < 1 and 1 or speed
        while not done do
            local current_value = cv()
            local v = step(current_value, nv, self:dt() * speed)
            nv(v)
            done = cv() == v
        end
    end)
end

function QuickAnim:Stop(o)
    o:stop()
    o:script().animating = false
end

function QuickAnim:Working(o)
    return o:script().animating
end

function QuickAnim:WorkColor(o, color, clbk, speed)
    o:animate(function()
        speed = speed or 5
        while o:color() ~= color do
            local n = self:dt() * speed
            o:set_color(Color(math.step(o:color().r, color.r, n), math.step(o:color().g, color.g, n), math.step(o:color().b, color.b, n)))
        end
        o:set_color(color)
        if clbk then
            clbk()
        end   
    end)
end
function QuickAnim:dt()
    local dt = coroutine.yield()
    if Application:paused() then
        dt = TimerManager:main():delta_time()
    end
    return dt
end