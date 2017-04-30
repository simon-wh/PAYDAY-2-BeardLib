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
        after = function() end,
        before = function() end,
        callback = function() end
    }
    local done 
    for i=1, #tbl, 2 do
        local k = tbl[i]
        local v = tbl[i + 1]
        if opt[k] ~= nil then
            opt[k] = v or opt[k]
        else
            table.insert(anim_tbl, {[k] = v})
        end       
    end            
    if anim_tbl.stop or stop == true then
        o:stop()
        anim_tbl.stop = nil
    end
    o:script().animating = tbl 
    o:animate(function()
        local mys = {}
        while not done do
            for _, anim in pairs(anim_tbl) do 
                for k,v in pairs(anim) do
                    local cv = o[k](o)
                    mys[k] = mys[k] or (math.abs(cv - v) * opt.speed)
                    mys[k] = mys[k] < 1 and 1 or mys[k]
                    opt.before()
                    o["set_"..k](o, math.step(cv, v, self:dt() * mys[k]))
                    opt.after()
                    done = o[k](o) == v 
                end
            end
        end
        for _, anim in pairs(anim_tbl) do 
            for k,v in pairs(anim) do
                o["set_"..k](o, v)    
            end
        end
        opt.before()
        opt.after()
        o:script().animating = nil
        opt.callback()
    end)
end

function QuickAnim:Stop(o)
    o:stop()
    o:script().animating = false
end

function QuickAnim:WorkColor(o, color, speed, clbk)
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