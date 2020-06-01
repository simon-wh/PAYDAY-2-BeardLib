--Input classes, mostly used in the editor and MenuUI.
--TODO: Expand/Write guide.
local InputUtils = {}
BeardLib.Utils.Input = InputUtils

function InputUtils:Class() return Input:keyboard() end
function InputUtils:Id(str) return str:id() end

--Keyboard
function InputUtils:Down(key) return self:Class():down(self:Id(key)) end
function InputUtils:Released(key) return self:Class():released(self:Id(key)) end
function InputUtils:Pressed(key) return self:Class():pressed(self:Id(key)) end
function InputUtils:Trigger(key, clbk) return self:Class():add_trigger(self:Id(key), SafeClbk(clbk)) end
function InputUtils:RemoveTrigger(trigger) return self:Class():remove_trigger(trigger) end
function InputUtils:TriggerRelease(key, clbk) return self:Class():add_release_trigger(self:Id(key), SafeClbk(clbk)) end
--Mouse
local MouseInput = clone(InputUtils)
Utils.MouseInput = MouseInput
function MouseInput:Class() return Input:mouse() end
--Keyboard doesn't work without Idstring however mouse works and if you don't use Idstring you can use strings like 'mouse 0' to differentiate between keyboard and mouse
--For example keyboard has the number 0 which is counted as left mouse button for mouse input, this solves it.
function MouseInput:Id(str) return str end

function InputUtils:TriggerDataFromString(str, clbk)
    local additional_key
    local key = str
    if string.find(str, "+") then
        local split = string.split(str, "+")
        key = split[1]
        additional_key = split[2]
    end
    return {key = key, additional_key = additional_key, clbk = clbk}
end

function InputUtils:Triggered(trigger, check_mouse_too)
    if not trigger.key then
        return false
    end
    if check_mouse_too and trigger.key:find("mouse") then
        return MouseInput:Pressed(trigger.key)
    end
    if trigger.additional_key then
        if self:Down(trigger.key) and self:Pressed(trigger.additional_key) then
            return true
        end
    elseif self:Pressed(trigger.key) then
        return true
    end
    return false
end