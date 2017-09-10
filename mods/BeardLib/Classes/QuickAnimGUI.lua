QuickAnim = QuickAnim or {}
QuickAnim.IgnoredValues = {
    ["speed"] = true, 
    ["stop"] = true, 
    ["wait"] = true, 
    ["callback"] = true, 
    ["after"] = true
}
function QuickAnim:Play(o, tbl)
    local stop
    if not alive(o) then
        return
    end
    local anim_tbl = {}
    local opt = {speed = 1}
    for k,v in pairs(tbl) do
        if self.IgnoredValues[k] then
            opt[k] = v
        else
            local sticky = not not k:match("sticky_")
            table.insert(anim_tbl, {key = sticky and k:gsub("sticky_", "") or k, value = v, sticky = sticky})
        end
    end
    if o:script().animating then
        if table.equals(o:script().animating, anim_tbl) then
            return
        else
            stop = true
        end
    end
    local done
    if opt.stop or stop == true then
        QuickAnim:Stop(o)
    end
    o:script().animating = anim_tbl
    local abs = math.abs
    local step = math.step
    local round = math.round_with_precision
    o:animate(function(o)
        local speeds = {}
        if opt.wait then wait(opt.wait) end
        while not done and #anim_tbl > 0 do
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
                        done = done and round(o[anim.key](o), 3) == round(anim.value, 3) --Luajit I swear ffs
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

function QuickAnim:Work(o, ...) --Deprecated..
    local tbl = {...}
    local anim_tbl = {}
    for i=1, #tbl, 2 do
        anim_tbl[tbl[i]] = tbl[i + 1]
    end
    self:Play(o, anim_tbl)
end

function QuickAnim:Stop(o)
    o:stop()
    o:script().animating = false
    o:script().animating_color = false
end

function QuickAnim:Working(o)
    return o:script().animating
end

function QuickAnim:WorkColor(o, color, clbk, speed)
    if o:script().animating_color then
        self:Stop()
    end
    o:animate(function()
        speed = speed or 1
        while o:color() ~= color do
            local n = self:dt() * speed
            o:set_color(Color(math.step(o:color().r, color.r, n), math.step(o:color().g, color.g, n), math.step(o:color().b, color.b, n)))
        end
        o:set_color(color)
        if clbk then
            clbk()
        end
        o:script().animating_color = nil
    end)
end
function QuickAnim:dt()
    local dt = coroutine.yield()
    if Application:paused() then
        dt = TimerManager:main():delta_time()
    end
    return dt
end