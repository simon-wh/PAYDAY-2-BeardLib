local mvec3_n_equal = mvector3.not_equal
local mvec3_set = mvector3.set
local mvec3_set_st = mvector3.set_static
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_div = mvector3.divide
local mvec3_lerp = mvector3.lerp
local mvec3_cpy = mvector3.copy
local mvec3_set_l = mvector3.set_length
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_dis = mvector3.distance
local mvec3_rot = mvector3.rotate_with
local math_abs = math.abs
local math_max = math.max
local math_clamp = math.clamp
local math_ceil = math.ceil
local math_floor = math.floor
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
function NavigationManager:init()
	self._debug = SystemInfo:platform() == Idstring("WIN32")  
	self._builder = NavFieldBuilder:new()
	self._get_room_height_at_pos = self._builder._get_room_height_at_pos
	self._check_room_overlap_bool = self._builder._check_room_overlap_bool
	self._door_access_types = self._builder._door_access_types
	self._opposite_side_str = self._builder._opposite_side_str
	self._perp_pos_dir_str_map = self._builder._perp_pos_dir_str_map
	self._perp_neg_dir_str_map = self._builder._perp_neg_dir_str_map
	self._dim_str_map = self._builder._dim_str_map
	self._perp_dim_str_map = self._builder._perp_dim_str_map
	self._neg_dir_str_map = self._builder._neg_dir_str_map
	self._x_dir_str_map = self._builder._x_dir_str_map
	self._dir_str_to_vec = self._builder._dir_str_to_vec
	self._geog_segment_size = self._builder._geog_segment_size
	self._grid_size = self._builder._grid_size
	self._rooms = {}
	self._room_doors = {}
	self._geog_segments = {}
	self._nr_geog_segments = nil
	self._visibility_groups = {}
	self._nav_segments = {}
	self._coarse_searches = {}
	self:set_debug_draw_state(true)
	self._covers = {}
	self._next_pos_rsrv_expiry = false
	if self._debug then
		self._nav_links = {}
	end
	self._quad_field = World:quad_field()
	self._quad_field:set_nav_link_filter(NavigationManager.ACCESS_FLAGS)
	self._pos_rsrv_filters = {}
	self._obstacles = {}
	if self._debug then
		self._pos_reservations = {}
	end
end
function NavigationManager:_safe_remove_unit(unit)
end
function NavigationManager:remove_AI_blocker_units()
end
function NavigationManager:update(t, dt)
	if self._debug then
		self._builder:update(t, dt)
		if self._draw_enabled then
			local options = self._draw_enabled
			local data = self._draw_data
			if data then
				local progress = math.clamp((t - data.start_t) / (data.duration * 0.5), 0, 1)
                if options.quads then
                    self:_draw_rooms(progress)
                end
                if options.doors then
                    self:_draw_doors(progress)
                end
                if options.blockers then
                    self:_draw_nav_blockers()
                end
                if options.vis_graph then
                    self:_draw_visibility_groups(progress)
                end
                if options.coarse_graph then
                    self:_draw_coarse_graph()
                end
                if options.nav_links then
                    self:_draw_anim_nav_links()
                end
                if options.covers then
                    self:_draw_covers()
                end
				if progress == 1 then
					self._draw_data.start_t = t
				end
			end
		end
	end
	self:_commence_coarce_searches(t)
end
function NavigationManager:build_complete_clbk(draw_options)
	self:_refresh_data_from_builder()
 
	self:set_debug_draw_state(draw_options)
	if self:is_data_ready() then
		BeardLib:log("Progress: Done!")
		self._load_data = self:get_save_data()
	end
	if self._build_complete_clbk then
		self._build_complete_clbk()
	end
end
function NavigationManager:search_coarse(params)
    if self._builder._building then
        return
    end
    local pos_to, start_i_seg, end_i_seg, access_pos, access_neg
    if params.from_seg then
        start_i_seg = params.from_seg
    elseif params.from_tracker then
        start_i_seg = params.from_tracker:nav_segment()
    end
    if params.to_seg then
        end_i_seg = params.to_seg
    elseif params.to_tracker then
        end_i_seg = params.to_tracker:nav_segment()
    end
    pos_to = params.to_pos or self._nav_segments[end_i_seg].pos
    if start_i_seg == end_i_seg then
        if params.results_clbk then
            params.results_clbk({
                {start_i_seg},
                {
                    end_i_seg,
                    mvec3_cpy(pos_to)
                }
            })
            return
        else
            return {
                {start_i_seg},
                {
                    end_i_seg,
                    mvec3_cpy(pos_to)
                }
            }
        end
    end
    if type_name(params.access_pos) == "table" then
        access_pos = self._quad_field:convert_access_filter_to_number(params.access_pos)
    elseif type_name(params.access_pos) == "string" then
        access_pos = self._quad_field:convert_nav_link_flag_to_bitmask(params.access_pos)
    else
        access_pos = params.access_pos
    end
    if params.access_neg then
        access_neg = self._quad_field:convert_nav_link_flag_to_bitmask(params.access_neg)
    else
        access_neg = 0
    end
    local new_search_data = {
        id = params.id,
        to_pos = mvec3_cpy(pos_to),
        start_i_seg = start_i_seg,
        end_i_seg = end_i_seg,
        seg_searched = {},
        discovered_seg = {
            [start_i_seg] = true
        },
        seg_to_search = {
            {i_seg = start_i_seg}
        },
        results_callback = params.results_clbk,
        verify_clbk = params.verify_clbk,
        access_pos = access_pos,
        access_neg = access_neg
    }
    if params.results_clbk then
        table.insert(self._coarse_searches, new_search_data)
    else
        local result = self:_execute_coarce_search(new_search_data)
        return result
    end
end
