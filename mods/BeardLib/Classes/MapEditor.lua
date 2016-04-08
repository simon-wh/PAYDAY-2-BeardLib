MapEditor = MapEditor or class()

local MOVEMENT_SPEED_BASE = 1000
local FAR_RANGE_MAX = 250000
local TURN_SPEED_BASE = 1
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
function MapEditor:init()
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(FAR_RANGE_MAX)
	self._camera_object:set_fov(75)
	self._vp = managers.viewport:new_vp(0, 0, 1, 1, "MapEditor", 10)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()	
	self._closed = true
    self._editor_all = World:make_slot_mask(1, 2, 3, 10, 11, 12, 15, 19, 29, 33, 34, 35, 36, 37, 38, 39)
	self._con =  managers.controller:create_controller("MapEditor", nil, true, 10)
	self._modded_units = {}
    self._selected_units = {}
    self._disabled_units = {}
	self._turn_speed = 5
    self.directory = "assets/extract/units"
	local keyboard = Input:keyboard()
	local key = Idstring("f10")
	if keyboard and keyboard:has_button(key) then
		self._show_con = Input:create_virtual_controller()
		self._show_con:connect(keyboard, key, Idstring("btn_toggle"))
		self._show_con:add_trigger(Idstring("btn_toggle"), callback(self, self, "show_key_pressed"))
	end	
    self._mission_elements = {
        "ElementAccessCamera",
        "ElementActionMessage",
        "ElementAIArea",
        "ElementAIAttention",
        "ElementAIGlobalEvent",
        "ElementAIGraph",
        "ElementAIRemove",
        "ElementAlertTrigger",
        "ElementAreaMinPoliceForce",
        "ElementAreaTrigger",
        "ElementAssetTrigger",
        "ElementAwardAchievment",
        "ElementBainState",
        "ElementBlackScreenVariant",
        "ElementBlurZone",
        "ElementCarry",
        "ElementSequenceTrigger",
        "ElementCharacterOutline",
        "ElementCharacterSequence",
        "ElementCharacterTeam",
        "ElementCinematicCamera",
        "ElementConsoleCommand",
        "ElementDangerZone",
        "ElementUnitSequenceTrigger",
        "ElementDialogue",
        "ElementDifficulty",
        "ElementDifficultyLevelCheck",
        "ElementDisableShout",
        "ElementDisableUnit",
        "ElementDropInState",
        "ElementEnableUnit",
        "ElementEnemyDummyTrigger",
        "ElementEnemyPrefered",
        "ElementEnvironmentOperator",
        "ElementEquipment",
        "ElementExperience",
        "ElementExplosion",
        "ElementExplosionDamage",
        "ElementFadeToBlack",
        "ElementFakeAssaultState",
        "ElementFeedback",
        "ElementFilter",
        "ElementFlashlight",
        "ElementFleepoint",
        "Elementgamedirection",
        "ElementHeat",
        "ElementHint",
        "ElementInstigator",
        "ElementInstigatorRule",
        "ElementInteraction",
        "ElementInventoryDummy",
        "ElementJobStageAlternative",
        "ElementJobValue",
        "ElementUnitSequence",
        "ElementKillZone", 
        "ElementLaserTrigger",
        "ElementLookatTrigger",
        "ElementLootBag", 
        "ElementLootSecuredTrigger",
        "ElementMandatoryBags",
        "ElementMissionEnd",
        "ElementMissionFilter",
        "ElementModifyPlayer",
        "ElementMoney",
        "ElementMotionPathMarker",
        "ElementNavObstacle",
        "ElementObjective",
        "ElementPickup",
        "ElementPlayerNumberCheck",
        "ElementPlayerSpawner",
        "ElementPlayerState",
        "ElementPlaySound",
        "ElementPlayerStyle",
        "ElementPointOfNoReturn", 
        "ElementPreplanning",
        "ElementLogicChance",
        "MissionScriptElement",
        "ElementPressure",
        "ElementProfileFilter",
        "ElementScenarioEvent",
        "ElementSecurityCmera",
        "ElementSequenceCharacter",
        "ElementSetOutline",
        "ElementSlowMotion",
        "ElementSmokeGrenade",
        "ElementSpawnCivilian",
        "ElementSpawnCivilianGroup",
        "ElementSpawnDeployable",
        "ElementSpawnEnemyDummy",
        "ElementSpawnEnemyGroup",
        "ElementSpawnGageAssignment",
        "ElementSpawnGrenade",
        "ElementSpecialObjective",
        "ElementSpecialObjectiveGroup",
        "ElementSpecialObjectiveTrigger",
        "ElementSpotter",
        "ElementStatistics",
        "ElementToggle",
        "ElementTeammateComment",
        "ElementTeamRelation",
        "ElementVehicleOperator",
        "ElementVehicleSpawner",
        "ElementVehicleTrigger",
        "ElementWayPoint",
        "ElementWhisperState",
    }
    self:create_menu() 
end

function MapEditor:mouse_pressed( button, x, y )
    if self._hide_panel:inside(x,y) then
        self._hide_panel:child("text"):set_text(self._hidden and "<" or ">")
        self._menu._panel:set_right(self._hidden and self._menu._panel:w() or 0  )
        self._hidden = not self._hidden
        self._hide_panel:set_left(self._menu._panel:right())
        return
    end
    if button == Idstring("0") or button == Idstring("1") and not self._menu._openlist and not self._menu._slider_hold and not self._menu._highlighted then
        self:select_unit(button == Idstring("1"))
    end      
end
function MapEditor:create_menu()
	self._menu = MenuUI:new({
		w = 325,
        tabs = true,
        background_color = Color(0.8, 0.8, 0.8),
        mousepressed = callback(self, self, "mouse_pressed"),
		create_items = callback(self, self, "create_items"),
	})
    self._hide_panel = self._menu._fullscreen_ws_pnl:panel({
        name = "hide_panel", 
        w = 16,
        h = 16,
        y = 16,
        layer = 25 
    })  
    self._hide_panel:rect({
        name = "bg", 
        halign="grow", 
        valign="grow",
        color = Color(0.8, 0.8, 0.8), 
        alpha = 0.8, 
    })    
    self._hide_panel:text({
        name = "text",
        text = "<",
        layer = 20,
        w = 16,
        h = 16,
        align = "center",      
        color = Color.black,
        font = "fonts/font_medium_mf",
        font_size = 16
    })    
    self._menu._fullscreen_ws_pnl:rect({
        name = "crosshair_vertical", 
        w = 2,
        h = 6,
        alpha = 0.8, 
        layer = 999 
    }):set_center(self._menu._fullscreen_ws_pnl:center())        
    self._menu._fullscreen_ws_pnl:rect({
        name = "crosshair_horizontal", 
        w = 6,
        h = 2,
        alpha = 0.8, 
        layer = 999 
    }):set_center(self._menu._fullscreen_ws_pnl:center())    
    self._hide_panel:set_left(self._menu._panel:right())  
end
function MapEditor:create_items(menu)
    local selected_unit = menu:NewMenu({
        name = "selected_unit",
        text = "Selected Unit",
        help = "",
    })          
    local selected_element = menu:NewMenu({
        name = "selected_element",
        text = "Selected element",
        help = "",
    })     
    local prefabs = menu:NewMenu({
        name = "prefabs",
        text = "Prefabs",
        help = "",
    })      
    local find = menu:NewMenu({
        name = "find",
        text = "Find",
        help = "",
    })       
    local save_options = menu:NewMenu({
        name = "save_options",
        text = "Save",
        help = "",
    })      
    local game_options = menu:NewMenu({
        name = "game_options",
        text = "Game",
        help = "",
    }) 
    self:create_unit_items(selected_unit)       
    self:create_selected_element_items(selected_element)       
    self:create_find_items(find)       
    self:create_save_options_items(save_options)       
    self:create_game_items(game_options)       
end
function MapEditor:create_selected_element_items(menu)
    menu:TextBox({
        name = "element_editor_name",
        text = "Name:",
        help = "",
        callback = callback(self, self, "set_element_data"),         
    })           
    menu:TextBox({
        name = "element_id",
        text = "id:",
        help = "",
        callback = callback(self, self, "set_element_data"),         
    })      
    menu:ComboBox({
        name = "element_class",
        text = "Class:",
        items = self._mission_elements,
        help = "",
        callback = callback(self, self, "set_element_data"),         
    })            
    menu:Slider({
        name = "element_position_x",
        text = "Position x",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })                         
    menu:Slider({
        name = "element_position_y",
        text = "Position y",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })                     
    menu:Slider({
        name = "element_position_z",
        text = "Position z",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })                    
    menu:Slider({
        name = "element_rotation_y",
        text = "Rotation yaw",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })                      
    menu:Slider({
        name = "element_rotation_p",
        text = "Rotation pitch",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })                       
    menu:Slider({
        name = "element_rotation_r",
        text = "Rotation roll",
        help = "",
        callback = callback(self, self, "set_element_data"), 
    })      
    menu:Table({
        name = "element_values",
        text = "Values:",
        callback = callback(self, self, "set_element_data"),         
    })           
    menu:Table({
        name = "element_on_executed",
        text = "On executed:",
        add = false,
        callback = callback(self, self, "set_element_data"),         
    })       
    menu:Button({
        name = "element_add_to_on_executed",
        text = "Add to element to execute",
        help = "",
        callback = callback(self, self, "show_add_element_dialog"),
    })           
    menu:Divider({
        text = "Executors",
        size = 30,
        color = Color.green,
    })    
end

function MapEditor:create_find_items(menu)
    menu:ClearItems()
    menu:Button({
        name = "units_browser_button",
        text = "Add Unit..",
        label = "main",        
        callback = callback(self, self, "browse")
    })            
    menu:Button({
        name = "elements_list_button",
        text = "Add Mission Element..",
        label = "main",        
        callback = callback(self, self, "show_elements_list")
    })        
    menu:Button({
        name = "all_mission_elements",
        text = "Mission Elements",
        label = "main",
        callback = callback(self, self, "load_all_mission_elements")
    })    
    menu:Button({
        name = "all_units",
        text = "Units",
        label = "main",       
        callback = callback(self, self, "load_all_units")
    })
end
function MapEditor:create_unit_items(menu)
    menu:Button({
        name = "add_to_prefabs",
        text = "Add to prefabs",
        value = "",
        help = "",
        callback = callback(self, self, "add_unit_to_prefabs"),         
    })      
    menu:TextBox({
        name = "unit_name",
        text = "Name: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),         
    })    
    menu:TextBox({
        name = "unit_id",
        text = "ID: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),         
    })             
    menu:ComboBox({
        name = "unit_mesh_variation",
        text = "Mesh variation: ",
        value = 1,
        items = {},
        help = "",
        callback = callback(self, self, "set_unit_data"),         
    })         
    menu:TextBox({
        name = "unit_path",
        text = "Unit path: ",
        value = "",
        help = "",
        callback = callback(self, self, "set_unit_data"),                 
    })     
    menu:Slider({
        name = "positionx",
        text = "Position x: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
    })     
    menu:Slider({
        name = "positiony",
        text = "Position Y: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
    })       
    menu:Slider({
        name = "positionz",
        text = "Position z: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
    })       
    menu:Slider({
        name = "rotationyaw",
        text = "Rotation yaw: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"), 
    })     
    menu:Slider({
        name = "rotationpitch",
        text = "Rotation pitch: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),       
    })       
    menu:Slider({
        name = "rotationroll",
        text = "Rotation roll: ",
        value = 0,
        help = "",
        callback = callback(self, self, "set_unit_data"),
    })          
    menu:Button({
        name = "unit_delete_btn",
        text = "Delete unit",
        help = "",
        callback = callback(self, self, "delete_unit"),
    })         
    menu:Divider({
        text = "Modifiers",
        size = 30,
        color = Color.green,
    })      	
end
function MapEditor:create_save_options_items(menu)
    local level =  "/" .. (Global.game_settings.level_id or "")
    menu:TextBox({
        name = "savepath",
        text = "Save path: ",
        value = BeardLib.MapsPath .. level,
        help = "",
    })         
    menu:Divider({
        name = "continents_div",        
        size = 30,
        text = "Continents",
    })   
    menu:ComboBox({
        name = "continents_filetype",
        text = "Type: ",
        value = 1,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
    })     
    menu:Button({
        name = "continents_savebtn",
        text = "Save",
        help = "",
        callback = callback(self, self, "save_continents"),
    })  
    menu:Divider({
        name = "missions_div",
        size = 30,
        text = "Missions",
    })
    menu:ComboBox({
        name = "missions_filetype",
        text = "Type: ",
        value = 2,
        items = {"custom_xml", "generic_xml", "json"},
        help = "",
    })     
    menu:Button({
        name = "missions_savebtn",
        text = "Save",
        help = "",
        callback = callback(self, self, "save_missions"),
    })       	
    menu:Divider({
        name = "nav_data_div",
        size = 30,
        text = "Navigation",
    })      
    menu:Button({
        name = "build_nav",
        text = "Build navdata",
        help = "",
        callback = callback(self, self, "_build_nav_segments"),
    })        
    menu:Button({
        name = "save_nav_data",
        text = "Save nav data",
        help = "",
        callback = callback(self, self, "save_nav_data"),
    })         
    menu:Button({
        name = "save_cover_data",
        text = "Save cover data",
        help = "",
        callback = callback(self, self, "save_cover_data"),
    })      
end
 
function MapEditor:set_unit(unit)
    self._selected_unit = unit
    self._selected_units = {}
    self._menu:GetItem("unit_name"):SetValue(alive(unit) and unit:unit_data().name_id or "")
    self._menu:GetItem("unit_path"):SetValue(alive(unit) and unit:unit_data().name or "")
    self._menu:GetItem("unit_id"):SetValue(alive(unit) and unit:unit_data().unit_id or "") 
    local mesh_variations = managers.sequence:get_editable_state_sequence_list(alive(unit) and unit:name() or "") or {}
    self._menu:GetItem("unit_mesh_variation"):SetItems(mesh_variations)
    self._menu:GetItem("unit_mesh_variation"):SetValue(alive(unit) and unit:unit_data().mesh_variation and table.get_key(mesh_variations, unit:unit_data().mesh_variation) or nil) 
    self._menu:GetItem("positionx"):SetValue(alive(unit) and unit:position().x or 0)
    self._menu:GetItem("positiony"):SetValue(alive(unit) and unit:position().y or 0)
    self._menu:GetItem("positionz"):SetValue(alive(unit) and unit:position().z or 0)   
    self._menu:GetItem("rotationyaw"):SetValue(alive(unit) and unit:rotation():yaw() or 0)
    self._menu:GetItem("rotationpitch"):SetValue(alive(unit) and unit:rotation():pitch() or 0)
    self._menu:GetItem("rotationroll"):SetValue(alive(unit) and unit:rotation():roll() or 0)

    local menu = self._menu:GetItem("selected_unit")
    menu:ClearItems("elements")    

    for _, element in pairs(managers.mission:get_modifiers_of_unit(unit)) do
        menu:Button({
            name = element.editor_name, 
            text = element.editor_name .. " [" .. (element.id or "") .."]",
            label = "elements",
            callback = callback(self, self, "_select_element", element)
        })                   
    end
end

function MapEditor:_build_nav_segments()
    QuickMenu:new( "Info", "This will disable the player and AI and build the nav data proceed?", 
    {[1] = {text = "Yes", callback = function() 
        local settings = {}
        local units = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                table.insert(units, unit)
            end
        end    
        for _, unit in ipairs(units) do
            local ray = World:raycast(unit:position() + Vector3(0, 0, 50), unit:position() - Vector3(0, 0, 150), nil, managers.slot:get_mask("all"))
            if ray and ray.position then
                table.insert(settings, {
                    position = unit:position(),
                    id = unit:editor_id(),
                    color = Color(),
                    location_id = unit:ai_editor_data().location_id
                })
            end
        end
        if #settings > 0 then
            for _, unit in pairs(World:find_units_quick("all")) do
                if unit:in_slot(managers.slot:get_mask("persons"))   then
                    unit:set_enabled(false) 
                    if unit:brain() then
                       unit:brain()._current_logic.update = nil
                    end
                    table.insert(self._disabled_units, unit)
                    for _, extension in pairs(unit:extensions()) do
                        unit:set_extension_update_enabled(Idstring(extension), false)
                    end
                end         
            end    
            managers.navigation:clear()
            managers.navigation:build_nav_segments(settings, callback(self, self, "_build_visibility_graph"))
        else
            BeardLib:log("No nav surface found.")
        end      
    end
    },[2] = {text = "No", is_cancel_button = true}}, true)    
end

function MapEditor:_build_visibility_graph()
    local all_visible = true
    local exclude, include
    if not all_visible then
        exclude = {}
        include = {}
        for _, unit in ipairs(World:find_units_quick("all")) do
            if unit:name() == Idstring("core/units/nav_surface/nav_surface") then
                exclude[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_exlude_filter
                include[unit:unit_data().unit_id] = unit:ai_editor_data().visibilty_include_filter
            end
        end
    end
    local ray_lenght = 150
    managers.navigation:build_visibility_graph(callback(self, self, "_finish_visibility_graph"), all_visible, exclude, include, ray_lenght)
end

function MapEditor:_finish_visibility_graph(menu, item)
    managers.groupai:set_state("none")
end
function MapEditor:show_add_element_dialog(menu, item)
    local items = {             
        {
            name = "id",
            text = "id:",
            value = "",
            filter = "number",             
            type = "TextBox",
        },      
        {
            name = "delay",
            text = "Delay:",
            value = "0",
            filter = "number", 
            type = "TextBox",           
        }
    }
    BeardLib.managers.Dialog:show({
        title = "Add element to on executed",
        callback = callback(self, self, "add_element_callback"),
        items = items,
        yes = "Add",
        no = "Close",
    })
end

function MapEditor:add_element_callback(items)
    local on_executed = self._menu:GetItem("element_on_executed")
    local i = (table.size(on_executed.items) / 2) + 1 
    on_executed:Add(i .. ":" .. "id", items[1].value)
    on_executed:Add(i .. ":" .. "delay", items[2].value)
    if on_executed.callback then
        on_executed.callback(on_executed.parent, on_executed)
    end              
end
function MapEditor:set_unit_data(menu, item)
    if alive(self._selected_unit) then
        self:set_position(Vector3(menu:GetItem("positionx").value, menu:GetItem("positiony").value, menu:GetItem("positionz").value), Rotation(menu:GetItem("rotationyaw").value, menu:GetItem("rotationpitch").value, menu:GetItem("rotationroll").value))
        if self._selected_unit:unit_data() and self._selected_unit:unit_data().unit_id then
            self._selected_unit:unit_data().name_id = self._menu:GetItem("unit_name").value
            self._selected_unit:unit_data().position = self._selected_unit:position()
            self._selected_unit:unit_data().rotation = self._selected_unit:rotation()
            local mesh_variations = managers.sequence:get_editable_state_sequence_list(self._selected_unit:name()) or {}
            self._selected_unit:unit_data().mesh_variation = mesh_variations[self._menu:GetItem("unit_mesh_variation").value]
            local mesh_variation = self._selected_unit:unit_data().mesh_variation
            if mesh_variation and mesh_variation ~= "" then
                managers.sequence:run_sequence_simple2(mesh_variation, "change_state", self._selected_unit)
            end
            self._selected_unit:unit_data().name = self._menu:GetItem("unit_path").value -- Later will add button to unit browser.
            managers.worlddefinition:set_unit(self._selected_unit:unit_data().unit_id, self._selected_unit:unit_data())
        end
    end
end

function MapEditor:add_unit_to_prefabs(menu, item)
    if self._selected_unit and not self._menu:GetItem("prefabs"):GetItem(self._selected_unit:unit_data().name_id) then
        self._menu:GetItem("prefabs"):Button({
            name = self._selected_unit:unit_data().name_id,
            text = self._selected_unit:unit_data().name_id,
            callback = callback(self, self, "SpawnUnit", self._selected_unit:unit_data().name)
        })
    end
end
function MapEditor:set_element(element)
    self._selected_element = element
    self._menu:GetItem("element_editor_name"):SetValue(element and element.editor_name or "")
    self._menu:GetItem("element_id"):SetValue(element and element.id or "")
    self._menu:GetItem("element_class"):SetValue(element and table.get_key(self._mission_elements, element.class) or 1) 
    self._menu:GetItem("element_position_x"):SetValue(element and element.values.position and element.values.position.x or 0)
    self._menu:GetItem("element_position_y"):SetValue(element and element.values.position and element.values.position.y or 0)
    self._menu:GetItem("element_position_z"):SetValue(element and element.values.position and element.values.position.z or 0)   
    self._menu:GetItem("element_rotation_y"):SetValue(element and element.values.rotation and element.values.rotation:yaw() or 0)
    self._menu:GetItem("element_rotation_p"):SetValue(element and element.values.rotation and element.values.rotation:pitch() or 0)
    self._menu:GetItem("element_rotation_r"):SetValue(element and element.values.rotation and element.values.rotation:roll() or 0)
    self._menu:GetItem("element_values"):SetValue(element and element.values or {})
    self._menu:GetItem("element_on_executed"):SetValue(element and element.values.on_executed or {})

    local menu = self._menu:GetItem("selected_element")
    menu:ClearItems("temp")

    for k, v in pairs(element.values) do
        if type(v) == "table" and k ~= "on_executed" then
            menu:Table({
                name = "element_" .. k,
                text = k,
                index = 11,
                label = "temp",
                items = v,
                callback = callback(self, self, "set_element_data"),         
            })    
        end
    end
    for _, element in pairs(managers.mission:get_executors_of_element(element)) do
        menu:Button({
            name = element.editor_name, 
            text = element.editor_name .. " [" .. (element.id or "") .."]",
            label = "temp",
            callback = callback(self, self, "_select_element", element)
        })                   
    end

end

function MapEditor:browse()
    local menu = self._menu:GetItem("find")
    menu:ClearItems()    
    self.current_dir = self.current_dir or self.directory
    BeardLib:log(self.current_dir)
    local folders = file.GetDirectories( self.current_dir )
    local files = file.GetFiles( self.current_dir )
    menu:Button({
        name = "back_button",
        text = "Back",
        callback = callback(self, self, "create_find_items")
    })      
    menu:Button({
        name = "uplevel_btn",
        text = "^ ( " .. (self.current_dir or self.custom_dir) .. " )",
        callback = callback(self, self, "folder_back"),
    })    
    menu:Button({
        name = "search_btn",
        text = "Search",
        callback = callback(self, self, "file_search"),
    })
    if folders then
        for _, folder in pairs(folders) do
            menu:Button({
                name = folder,
                text = folder,
                label = "temp",
                callback = callback(self, self, "folder_click"),
            })
        end
    end
    if files then
        for _,file in pairs(files) do
            if file:match("unit") then
                menu:Button({
                    name = file:gsub(".unit", ""),
                    text = file,
                    label = "temp",
                    path = self.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""),
                    color = PackageManager:has(Idstring("unit"), Idstring(self.current_dir:gsub("assets/extract/", "") .. "/" .. file:gsub(".unit", ""))) and Color.green or Color.red,
                    callback = callback(self, self, "file_click"),
                })
            end
        end 
    end
end

function MapEditor:file_search(menu, item)
    self._is_searching = false
    managers.system_menu:show_keyboard_input({
        text = "", 
        title = "Search:", 
        callback_func = callback(self, self, "search", self.directory),
    })  
end

function MapEditor:folder_back(menu, item)
    if self._is_searching then
        self._is_searching = false
        self:browse()
    else
        local str = string.split(self.current_dir, "/")
        table.remove(str, #str)
        self.current_dir = table.concat(str, "/")
        self:browse()
    end
end
function MapEditor:search(path, success, search)
    if not success then
        return
    end        
    local menu = self._menu:GetItem("find") 
    if not self._is_searching then
        menu:ClearItems("temp")
        self._is_searching = true
    end
    for _, unit_path in pairs(BeardLib.DBPaths["unit"]) do
        local split = string.split(unit_path, "/")
        local unit = split[#split]
        if unit:match(search) then
            menu:Button({
                name = unit,
                text = unit,
                path = unit_path,
                label = "temp",
                color = PackageManager:has(Idstring("unit"), Idstring(unit_path)) and Color.green or Color.red,
                callback = callback(self, self, "file_click"),
            })
        end         
    end 
end

function MapEditor:folder_click(menu, item)
    self.current_dir = self.current_dir .. "/" .. item.text
    self:browse(self)
    local after_folder_click = item.parent.after_folder_click
    if after_folder_click then
        after_folder_click()
    end
end

function MapEditor:create_game_items(menu)
    menu:Button({
        name = "teleport_player",
        text = "Teleport player",
        help = "",
        callback = callback(self, self, "drop_player"),
    })      
    menu:Button({
        name = "position_debug",
        text = "Position debug",
        help = "",
        callback = callback(self, self, "position_debug"),
    })
    menu:Slider({
        name = "camera_speed",
        text = "Camera speed",
        help = "",
        max = 10,
        min = 0,
        step = 0.1,
        value = 2,
    })   
    menu:Toggle({
        name = "units_visibility",
        text = "Editor units visibility",
        help = "",
        value = false,
        callback = callback(self, self, "set_editor_units_visible"),
    })      
    menu:Toggle({
        name = "units_highlight",
        text = "Highlight all units",
        help = "",
        value = false,
    })   
    menu:Toggle({
        name = "show_elements",
        text = "Show elements",
        help = "",
        value = false,
    })       
    menu:Toggle({
        name = "draw_nav_segments",
        text = "Draw nav segments",
        help = "",
        callback = callback(self, self, "draw_nav_segments"),
        value = false,
    })
    menu:Table({
        name = "draw_nav_segments_options",
        text = "Draw:",
        add = false,
        remove = false,
        help = "",
        items = { 
            quads = true,
            doors = true,
            blockers = true,
            vis_graph = true,
            coarse_graph = true,
            nav_links = true,
            covers = true,
        },
        callback = callback(self, self, "draw_nav_segments"),
        value = false,
    })

    menu:Toggle({
        name = "pause_game",
        text = "Pause game",
        help = "",
        value = false,
        callback = callback(self, self, "pause_game")
    })          
end
 
function MapEditor:load_all_mission_elements(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "create_find_items")
        })  
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_mission_elements")         
        }) 
    else
        searchbox = self._menu:GetItem("searchbox")    
    end      
    for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do            
                    if #menu._items < 120 and (not searchbox.value or searchbox.value == "" or string.match(element.editor_name, searchbox.value) or string.match(element.id, searchbox.value)) or string.match(element.class, searchbox.value) then
                        local _element = managers.mission:get_mission_element(element.id)
                        menu:Button({
                            name = element.editor_name, 
                            text = element.editor_name .. " [" .. element.id .."]",
                            label = "select_buttons",
                            color = _element and (_element.values.enabled and Color.green or Color.red) or nil,
                            callback = callback(self, self, "_select_element", element)
                        })            
                    end
                end
            end
        end
    end
end
function MapEditor:show_elements_list(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "create_find_items")
        })  
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "show_elements_list")         
        }) 
    else
        searchbox = self._menu:GetItem("searchbox")    
    end      
    for k, element in pairs(self._mission_elements) do 
        if (not searchbox.value or searchbox.value == "" or string.match(element, searchbox.value)) then
            menu:Button({
                name = element, 
                text = element,
                label = "select_buttons",
                callback = callback(self, self, "add_element", element)
            })            
        end
    end
end
function MapEditor:load_all_units(menu, item)
    menu:ClearItems("main")
    menu:ClearItems("select_buttons")
    local searchbox
    if not self._menu:GetItem("searchbox") then
        menu:Button({
            name = "back_button",
            text = "Back",
            callback = callback(self, self, "create_find_items")
        })  
        searchbox = menu:TextBox({
            name = "searchbox",
            text = "Search what: ",
            callback = callback(self, self, "load_all_units")         
        }) 
    else
        searchbox = self._menu:GetItem("searchbox")    
    end      
    for k, unit in pairs(World:find_units_quick("all")) do
        if #menu._items < 120 and unit:unit_data() and (unit:unit_data().name_id ~= "none" and not searchbox.value or searchbox.value == "" or string.match(unit:unit_data().name_id, searchbox.value or "") or string.match(unit:unit_data().unit_id, searchbox.value or "")) then
            menu:Button({
                name = unit:unit_data().name_id,
                text = unit:unit_data().name_id .. " [" .. (unit:unit_data().unit_id or "") .."]",
                label = "select_buttons",
                callback = callback(self, self, "_select_unit", unit)
            })            
        end
    end
end

function MapEditor:set_element_data(menu, item)
    if self._selected_element then
        for k,v in pairs(menu:GetItem("element_values").items) do
            self._selected_element.values[k] = v 
        end
        self._selected_element.values.on_executed = {}
        for i=1, (table.size(menu:GetItem("element_on_executed").items) / 2) do
            table.insert(self._selected_element.values.on_executed, {})
        end
        for k,v in pairs(menu:GetItem("element_on_executed").items) do
            local split = string.split(k, ":") 
            local i = tonumber(split[1])
            if #split == 2 then
                if self._selected_element.values.on_executed[i] then
                    self._selected_element.values.on_executed[i][split[2]] = tonumber(v)
                end
            end
        end
        self._selected_element.values.position = Vector3(menu:GetItem("element_position_x").value, menu:GetItem("element_position_y").value, menu:GetItem("element_position_z").value)
        self._selected_element.values.rotation = Rotation(menu:GetItem("element_rotation_y").value, menu:GetItem("element_rotation_p").value, menu:GetItem("element_rotation_r").value)
        self._selected_element.editor_name = menu:GetItem("element_editor_name").value
    end
end

function MapEditor:_select_unit(unit, menu, item)
    self._menu:SwitchMenu(self._menu:GetItem("selected_unit"))
    self:set_unit(unit)
end
function MapEditor:_select_element(element, menu, item)
    self._menu:SwitchMenu(self._menu:GetItem("selected_element"))
    self:set_element(element)
end
function MapEditor:add_element(element, menu, item)
    self:set_element(managers.mission:add_element(element))    
    self._menu:SwitchMenu(self._menu:GetItem("selected_element"))
end
 
 
function MapEditor:delete_unit(menu, item)
	if alive(self._selected_unit) then
		managers.worlddefinition:delete_unit(self._selected_unit)		
		World:delete_unit(self._selected_unit)
	end
    for _, unit in pairs(self._selected_units) do
        if alive(unit) then
            managers.worlddefinition:delete_unit(unit)        
            World:delete_unit(unit)
        end                    
    end 
    self:set_unit()    
end
function MapEditor:set_editor_units_visible(menu, item)
	for _, unit in pairs(World:find_units_quick("all")) do
		if type(unit:unit_data()) == "table" and (unit:unit_data().only_visible_in_editor or unit:unit_data().only_exists_in_editor) then
			unit:set_visible( self._menu:GetItem("units_visibility").value )
		end
	end
end
function MapEditor:draw_nav_segments( menu, item )
    managers.navigation:set_debug_draw_state(menu:GetItem("draw_nav_segments").value and menu:GetItem("draw_nav_segments_options").items or false )
end
function MapEditor:SpawnUnit( unit_path, unit_data )
    local unit
    local cam = managers.viewport:get_current_camera()
    local pos = unit_data and unit_data.position or cam:position() + cam:rotation():y()
    local rot = unit_data and unit_data.rotation or Rotation(0,0,0)
    local split = string.split(unit_path, "/")

    if MassUnitManager:can_spawn_unit(Idstring(unit_path)) then
        unit = MassUnitManager:spawn_unit(Idstring(unit_path), pos , rot )
    else
        unit = CoreUnit.safe_spawn_unit(unit_path, pos, rot)
    end 
    if not unit.unit_data or not unit:unit_data()  then
        BeardLib:log(unit_path .. " has no unit data...")
    else
        unit:unit_data().name_id = split[#split] .."_".. managers.worlddefinition:get_unit_number(unit_path)
        unit:unit_data().unit_id = math.random(999999)
        unit:unit_data().name = unit_path
        unit:unit_data().position = unit:position()
        unit:unit_data().rotation = unit:rotation()
    end
    self:_select_unit(unit)

    managers.worlddefinition:add_unit(unit)   
end
function MapEditor:file_click(menu, item)
	local unit_path = self.current_dir:gsub("assets/extract/", "") .. "/" .. item.name:gsub(".unit", "")
	local unit_path = item.path
	if item.color == Color.red then
		QuickMenu:new( "Warning", "Unit is not loaded, load it? (Might crash)", 
		{[1] = {text = "Yes", callback = function()	
			managers.dyn_resource:load(Idstring("unit"), Idstring(unit_path), DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)
			self:browse(self._current_menu)
			self:SpawnUnit(unit_path)			
  		end
  		},[2] = {text = "No", is_cancel_button = true}}, true)
	else
		self:SpawnUnit(unit_path)
	end
end
function MapEditor:save_continents(menu)
	local item = menu:GetItem("continents_filetype")
	local type = item.items[item.value]
	local path = menu:GetItem("savepath").value
	local world_def = managers.worlddefinition
	if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end
    if file.DirectoryExists( path ) then
		for continent_name, _ in pairs(world_def._continent_definitions) do
			if menu:GetItem("continent_" .. continent_name).value then
				world_def:save_continent(continent_name, type, path)
			end
		end
	else
		BeardLib:log("Directory doesn't exists(Failed to create directory?)")
	end
end
function MapEditor:save_missions(menu)
	local item = menu:GetItem("missions_filetype")
	local type = item.items[item.value]
	local path = menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end    
	if file.DirectoryExists( path ) then
		for mission_name, _ in pairs(managers.mission._missions) do
			if menu:GetItem("mission_" .. mission_name).value then
				managers.mission:save_mission_file(mission_name, type, path)
			end
		end
	else
        BeardLib:log("Directory doesn't exists(Failed to create directory?)")
	end
end

function MapEditor:save_nav_data(menu)
    local path = menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end    
    if file.DirectoryExists( path ) then
        if managers.navigation:get_save_data() then
            local file = io.open(path .. "/nav_manager_data.nav_data", "w+")
            file:write(managers.navigation._load_data)
            file:close() 
        else
            BeardLib:log("Save data is not ready!")
        end
    else
        BeardLib:log("Directory doesn't exists(Failed to create directory?)")
    end 
end

function MapEditor:save_cover_data(menu)
    local path = menu:GetItem("savepath").value
    if not file.DirectoryExists( path ) then
        os.execute("mkdir " .. path:gsub("/" , "\\"))
    end    
    if file.DirectoryExists( path ) then
        local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
        local covers = {
            positions = {},
            rotations = {}
        }
        for i, unit in pairs(all_cover_units) do
            local pos = Vector3()
            unit:m_position(pos)
            mvector3.set_static(pos, math.round(pos.x), math.round(pos.y), math.round(pos.z))
            table.insert(covers.positions, pos)
            local rot = unit:rotation()
            table.insert(covers.rotations, math.round(rot:yaw()))
        end
        local file = io.open(path .. "/cover_data.cover_data", "w+")
        local new_data = _G.BeardLib.managers.ScriptDataConveter:GetTypeDataTo(covers, "custom_xml")    
        file:write(new_data)
        file:close() 
    else
        BeardLib:log("Directory doesn't exists(Failed to create directory?)")
    end 
end

function MapEditor:load_continents(continents)
    for continent_name, _ in pairs(continents) do
        self._menu:GetItem("save_options"):Toggle({
            name = "continent_" .. continent_name,
            text = "Save continent: " .. continent_name,
            help = "",
            index = 5,
            value = true,
        })    
    end
end
function MapEditor:load_missions(missions)
    for mission_name, _ in pairs(missions) do
	    self._menu:GetItem("save_options"):Toggle({
	        name = "mission_" .. mission_name,
	        text = "Save mission: " .. mission_name,
	        help = "",
            index = 8,
	        value = true,
	    })    
    end
end

function MapEditor:show_key_pressed()
	if self._closed then
		self:enable()
		self._menu:enable()
	else 
		self:disable()
		self._menu:disable()
	end
	self._closed = not self._closed
end

function MapEditor:drop_player()
	local rot_new = Rotation(self._camera_rot:yaw(), 0, 0)
	game_state_machine:current_state():freeflight_drop_player(self._camera_pos, rot_new)
end
function MapEditor:select_unit(select_more)
	local cam = self._camera_object
	local ray
	if self._menu:GetItem("units_visibility").value then
        ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000, "ray_type", "body editor walk", "slot_mask", self._editor_all)
    else
        ray = World:raycast("ray", cam:position(), cam:position() + cam:rotation():y() * 1000)
    end
	if ray then
		log("ray hit " .. tostring(ray.unit:unit_data().name_id).. " " .. ray.body:name())
        if not select_more then
    		local current_unit
    		if self._selected_unit == ray.unit then
    			current_unit = true
    		end
    		if alive(self._selected_unit) then
    			self:set_unit(nil)
    		end
    		if not current_unit then
    			self:set_unit(ray.unit)
    			self._selected_body = ray.body
    			self._modded_units[ray.unit:editor_id()] = self._modded_units[ray.unit:editor_id()] or {}
    			self._modded_units[ray.unit:editor_id()]._default_position = self._modded_units[ray.unit:editor_id()]._default_position or ray.unit:position()
    			self._modded_units[ray.unit:editor_id()]._default_rotation = self._modded_units[ray.unit:editor_id()]._default_rotation or ray.unit:rotation()
    			self._modded_units[self._selected_unit:editor_id()]._modded_offset_position = self._modded_units[self._selected_unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
    			self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation = self._modded_units[self._selected_unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
    		end
    		if self._modded_units[ray.unit:editor_id()] and self._modded_units[ray.unit:editor_id()]._modded_offset_position then
    			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_position or Vector3(0, 0, 0)
    		end
    		if self._modded_units[ray.unit:editor_id()] and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation then
    			local modded_offset = self._selected_unit and self._modded_units[ray.unit:editor_id()]._modded_offset_rotation or Rotation(0, 0, 0)
    		end
        elseif ray.unit ~= self._selected_unit then
            table.insert(self._selected_units, ray.unit)
        end
	else
		log("no ray")
	end
end

 
function MapEditor:set_unit_enabled(enabled)
	if self._selected_unit then
		self._selected_unit:set_enabled(enabled)
	end
end

function MapEditor:set_camera(pos, rot)
	if pos then
		self._camera_object:set_position((alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3()) + pos)
		self._camera_pos = pos
	end
	if rot then
		self._camera_object:set_rotation(rot)
		self._camera_rot = rot
	end
end
function MapEditor:disable()
	self._closed = false
	self._con:disable()
	self._vp:set_active(false)
	if type(managers.enemy) == "table" then
		managers.enemy:set_gfx_lod_enabled(true)
	end
    if managers.hud then
        managers.hud:set_enabled()
    end
end
function MapEditor:enable()
	local active_vp = managers.viewport:first_active_viewport()
	if active_vp then
		self._start_cam = active_vp:camera()
		if self._start_cam then
			local pos = self._start_cam:position() - (alive(self._attached_to_unit) and self._attached_to_unit:position() or Vector3())
			self:set_camera(pos, self._start_cam:rotation())
		end
	end
	self._closed = true
	self._vp:set_active(true)
	self._con:enable()
	if managers.enemy then
		managers.enemy:set_gfx_lod_enabled(false)
	end
    if managers.hud then
        managers.hud:set_disabled()
    end
end

function MapEditor:pause_game(menu, item)
   Application:set_pause(item.value)
end
function MapEditor:paused_update(t, dt)
    self:update(t, dt)
end
function MapEditor:update(t, dt)
	local main_t = TimerManager:main():time()
	local main_dt = TimerManager:main():delta_time()	

	local brush = Draw:brush(Color(0, 0.5, 0.85))
	if alive(self._selected_unit) and managers.viewport:get_current_camera() then
		Application:draw(self._selected_unit, 0, 0.5, 0.85)	
        brush:sphere(self._selected_unit:position(), 10)        
    	local cam_up = managers.viewport:get_current_camera():rotation():z()
    	local cam_right = managers.viewport:get_current_camera():rotation():x()		
    	brush:set_font(Idstring("fonts/font_medium"), 32)
    	brush:center_text(self._selected_unit:position() + Vector3(-10, -10, 200), self._selected_unit:unit_data().name_id .. "[ " .. self._selected_unit:editor_id() .. " ]", cam_right, -cam_up)
	end
    for _, unit in pairs(self._selected_units) do
        Application:draw(unit, 0, 0.5, 0.85)   
        local brush = Draw:brush(Color(0, 0.5, 0.85))
        brush:sphere(unit:position(), 5)
    end
	if self._menu:GetItem("units_highlight").value then
		for _, unit in pairs(World:find_units_quick("all")) do
			if unit:editor_id() ~= -1 then
                local cam_up = managers.viewport:get_current_camera():rotation():z()
                local cam_right = managers.viewport:get_current_camera():rotation():x()                     
				Application:draw(unit, 1, 1,1)
                brush:set_font(Idstring("fonts/font_medium"), 32)
             --   brush:center_text(unit:position() + Vector3(-10, -10, 200), unit:editor_id(), cam_right, -cam_up) --Sometimes you can't select and can't find the unit..
			end					
		end
	end	
	if self:enabled() then
        if self._selected_unit and Input:keyboard():down(Idstring("left ctrl")) then
            if Input:keyboard():down(Idstring("f")) then
                self:set_camera(self._selected_unit:position())
            elseif Input:keyboard():down(Idstring("g")) then
                self:set_camera(self._selected_element.values.position)
            end 
        end
		self:update_camera(main_t, main_dt)
	end
end
function MapEditor:update_camera(t, dt)
	if self._menu._highlighted and not Input:keyboard():down(Idstring("left shift")) then
		return
	end
	local axis_move = self._con:get_input_axis("freeflight_axis_move")
	local axis_look = self._con:get_input_axis("freeflight_axis_look")
	local btn_move_up = self._con:get_input_float("freeflight_move_up")
	local btn_move_down = self._con:get_input_float("freeflight_move_down")
	local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
	move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
	local move_delta = move_dir * self._menu:GetItem("camera_speed").value * MOVEMENT_SPEED_BASE * dt
	local pos_new = self._camera_pos + move_delta
	local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed * TURN_SPEED_BASE
	local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
	local rot_new 
	if Input:keyboard():down(Idstring("left shift")) then
		rot_new = Rotation(yaw_new, pitch_new, 0)
	end
	if not CoreApp.arg_supplied("-vpslave") then
		self:set_camera(pos_new, rot_new)
	end
end

function MapEditor:set_position(position, rotation)
	local unit = self._selected_unit
	unit:set_position(position)
	unit:set_rotation(rotation)
	local objects = unit:get_objects_by_type(Idstring("model"))
	for _, object in pairs(objects) do
		object:set_visibility(not object:visibility())
		object:set_visibility(not object:visibility())
	end
	local num = unit:num_bodies()
	for i = 0, num - 1 do
		local unit_body = unit:body(i)
		unit_body:set_enabled(not unit_body:enabled())
		unit_body:set_enabled(not unit_body:enabled())
	end
end
function MapEditor:enabled()
	return not self._closed
end
function MapEditor:position_debug()
	local p = self._camera_pos
	log("Camera Pos: " .. tostring(p))
    if self._selected_unit then
        log("Selected Unit[" .. self._selected_unit:unit_data().name_id .. "] Pos: " .. tostring(self._selected_unit:position()))
        log("Selected Unit[" .. self._selected_unit:unit_data().name_id .. "] Rot: " .. tostring(self._selected_unit:rotation()))
    end
end