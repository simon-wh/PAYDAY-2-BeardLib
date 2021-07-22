--Input classes, mostly used in the editor and MenuUI.
--TODO: Expand/Write guide.
local InputUtils = {}
BeardLib.Utils.Input = InputUtils

function InputUtils:Class() return Input:keyboard() end
function InputUtils:Id(str) return str:id() end

--Keyboard
function InputUtils:Down(key) return self:Class():down(self:Id(key)) end
function InputUtils:DownList() 
    local device = self:Class()
    local orig_down_list = device:down_list()
    local down_list = {}
    for _, key in pairs(orig_down_list) do
        local _key = device:button_name_str(device:button_name(key))
        if device_name == "mouse" and not _key:find("mouse") then
            _key = "mouse " .. _key
        end
        table.insert(down_list, device:button_name_str(device:button_name(key)))
    end
    return down_list
end
function InputUtils:Released(key) return self:Class():released(self:Id(key)) end
function InputUtils:Pressed(key) return self:Class():pressed(self:Id(key)) end
function InputUtils:Trigger(key, clbk) return self:Class():add_trigger(self:Id(key), SafeClbk(clbk)) end
function InputUtils:RemoveTrigger(trigger) return self:Class():remove_trigger(trigger) end
function InputUtils:TriggerRelease(key, clbk) return self:Class():add_release_trigger(self:Id(key), SafeClbk(clbk)) end

function InputUtils:GetInputDevices(no_keyboard, no_mouse)
    local input_devices = {}
    if not no_keyboard then
        input_devices.keyboard = self
    end
    if not no_mouse then
        input_devices.mouse = BeardLib.Utils.MouseInput
    end
    if not no_controller then
        input_devices.controller = BeardLib.Utils.ControllerInput
    end
    return input_devices
end

function InputUtils:TriggerDataFromString(str, clbk)
    local data = self:GetTriggerData(str, clbk)
    return {key = data.keys[1], additional_key = data.keys[2], clbk = data.clbk}
end

function InputUtils:GetTriggerData(str, clbk)
    return {keys = string.split(str, "+"), clbk = clbk}
end

function InputUtils:IsTriggered(trigger, check_mouse_too)
    if not trigger.keys or #trigger.keys == 0 then
        return false
    end

    local is_held = false
    local devices = self:GetInputDevices()
    if not check_mouse_too then
        devices.mouse = nil
    end

    for i, key in pairs(trigger.keys) do
        for device_name, device in pairs(devices) do
            if device_name ~= "mouse" or key:find("mouse") then
                local last = i == #trigger.keys
                if last and self:Pressed(key) or not last and self:Down(key) then
                    is_held = true
                else
                    return false
                end
            end
        end
    end
    return is_held
end

-- Old version of IsTriggered before keys were merged into a table
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

--Mouse
local MouseInput = clone(InputUtils)
BeardLib.Utils.MouseInput = MouseInput
function MouseInput:Class() return Input:mouse() end
--Keyboard doesn't work without Idstring however mouse works and if you don't use Idstring you can use strings like 'mouse 0' to differentiate between keyboard and mouse
--For example keyboard has the number 0 which is counted as left mouse button for mouse input, this solves it.
function MouseInput:Id(str) return str end

--Controller
local ControllerInput = clone(InputUtils)
BeardLib.Utils.ControllerInput = ControllerInput
function ControllerInput:Class() 
    if managers.menu and managers.menu:active_menu() and managers.menu:active_menu().input then
        return managers.menu:active_menu().input:get_controller() 
    else
        return Input:keyboard()
    end
end
