--Deprecated class, use play_anim instead.
QuickAnim = QuickAnim or {}
local ignored = {speed = true, stop = true, wait = true, callback = true, easing = true, after = true}
function QuickAnim:Play(o, tbl)
    local opt = {set = {}, stop = false}
    for k,v in pairs(tbl) do
        if ignored[k] then
            opt[k] = v
        else
            local sticky = not not k:match("sticky_")
            opt.set[sticky and k:gsub("sticky_", "") or k] = sticky and {value = v, sticky = true} or v
        end
    end
    play_anim(o, opt)
end

function QuickAnim:Work(o, ...) end
function QuickAnim:Stop(o) end
function QuickAnim:Working(o) return o:script().animating end
function QuickAnim:WorkColor(o, color, clbk, speed) play_color(o, color, {callback = clbk}) end