local RecipeChange = require "__RemoteConfiguration__/recipe-change"

-- These entity types can be opened remotely anyway
local entity_type_blacklist = {
  ["locomotive"] = true,
  ["train-stop"] = true,
  ["electric-pole"] = true,
}

local function increase_range(player)
  if player.character and player.character_reach_distance_bonus < 200000 then
    player.character_reach_distance_bonus = player.character_reach_distance_bonus + 200000
  end
end

local function reset_range(player)
  if not player.character then return end
  while player.character_reach_distance_bonus >= 200000 do
    player.character_reach_distance_bonus = player.character_reach_distance_bonus - 200000
  end
end

local function can_reach_entity(player, entity)
  -- Check if player can reach entity disregarding whatever reach bonus we have given the player
  if not player.character then return true end
  local reach_distance_bonus = player.character_reach_distance_bonus
  reset_range(player)
  local can_reach = player.can_reach_entity(entity)
  player.character_reach_distance_bonus = reach_distance_bonus
  return can_reach
end

local function is_out_of_range_gui_open(player)
  local opened = player.opened
  if opened and player.opened_gui_type == defines.gui_type.entity and not can_reach_entity(player, opened) then
    return true
  end
  return false
end

local wires = {["red-wire"] = true, ["green-wire"] = true, ["copper-cable"] = true}
local function is_holding_wire(player)
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read then
    return wires[cursor_stack.name]
  end
end

script.on_event("rc-open-gui",
  function(event)
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then return end
    local selected = player.selected

    if selected then
      if entity_type_blacklist[selected.type] then return end
      reset_player(player)  -- Ensures that can_reach_entity is accurate
      local out_of_reach = not can_reach_entity(player, selected)
      local map_mode = player.render_mode == defines.render_mode.chart_zoomed_in
      if out_of_reach or map_mode then
        player.opened = nil  -- Triggers on_gui_closed before we open the GUI we care about
        if out_of_reach then
          increase_range(player)
          player.permission_group = game.permissions.get_group("Remote Configuration GUI opened")
        end
        player.opened = selected
        if player.opened_gui_type == defines.gui_type.entity then
          RecipeChange.on_remote_gui_opened(player)
        else
          -- Opening GUI failed
          reset_player(player)
        end
      end
    end
  end
)

function reset_player(player)
  player.permission_group = game.permissions.get_group("Default")
  reset_range(player)
end
script.on_event(defines.events.on_gui_closed,
  function(event)
    local player = game.get_player(event.player_index)
    RecipeChange.on_gui_closed(player)
    if is_holding_wire(player) then return end
    reset_player(player)
  end
)

-- Allows wires to be fast-transfered or placed in chests when close, but not when far away
local function recalculate_wire_permissions(event)
  local player = game.get_player(event.player_index)
  if not is_holding_wire(player) then return end

  local opened = player.opened
  if player.selected and can_reach_entity(player, player.selected) then
    reset_player(player)
  elseif player.opened_self or (opened and player.opened_gui_type == defines.gui_type.entity and can_reach_entity(player, opened)) then
    reset_player(player)
  else
    increase_range(player)
    player.permission_group = game.permissions.get_group("Remote Configuration GUI opened")
  end
end
script.on_event(defines.events.on_player_changed_position, recalculate_wire_permissions)
script.on_event(defines.events.on_selected_entity_changed, recalculate_wire_permissions)
script.on_event(defines.events.on_gui_opened, recalculate_wire_permissions)

script.on_event(defines.events.on_player_cursor_stack_changed,
  function(event)
    local player = game.get_player(event.player_index)
    if is_holding_wire(player) then
      recalculate_wire_permissions(event)
    else
      if not is_out_of_range_gui_open(player) then
        reset_player(player)
      end
    end
  end
)

script.on_event("rc-paste-entity-settings",
  function(event)
    local player = game.get_player(event.player_index)
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then return end

    local selected = player.selected
    if not selected then return end

    local in_reach = can_reach_entity(player, selected)
    if in_reach then return end  -- Let vanilla handle this

    local entity_copy_source = player.entity_copy_source
    if not entity_copy_source then return end

    removed_items = selected.copy_settings(entity_copy_source, player)
    local surface = selected.surface
    local position = selected.position
    local force = player.force
    for name, count in pairs(removed_items) do
      surface.spill_item_stack(
        position,
        {name = name, count = count},
        true,  -- enabled_looted
        force,  -- force for deconstruction
        false  -- allow_on_belts
      )
    end
  end
)


local function create_permission_group(config_changed_data)
  local permissions = game.permissions

  if config_changed_data then
    -- in on_configuration_changed
    if config_changed_data.mod_changes and config_changed_data.mod_changes["RemoteConfiguration"] then
      for _, player in pairs(game.players) do
        reset_player(player)
        player.opened = nil
      end
    end
    if permissions.get_group("Remote Configuration GUI opened") then
      permissions.get_group("Remote Configuration GUI opened").destroy()
    end
  end
  if permissions.get_group("Remote Configuration GUI opened") then
    return
  end
  local group = permissions.create_group("Remote Configuration GUI opened")
  if not group then
    log("Group not created!!!")
    game.print("[Remote Configuration] Group not created, please report!")
    return
  end
  group.set_allows_action(defines.input_action.begin_mining, false)
  group.set_allows_action(defines.input_action.begin_mining_terrain, false)
  group.set_allows_action(defines.input_action.build, false)
  group.set_allows_action(defines.input_action.build_rail, false)
  group.set_allows_action(defines.input_action.build_terrain, false)
  group.set_allows_action(defines.input_action.cursor_split, false)
  group.set_allows_action(defines.input_action.cursor_transfer, false)
  group.set_allows_action(defines.input_action.fast_entity_split, false)
  group.set_allows_action(defines.input_action.fast_entity_transfer, false)
  group.set_allows_action(defines.input_action.inventory_split, false)
  group.set_allows_action(defines.input_action.inventory_transfer, false)
  group.set_allows_action(defines.input_action.place_equipment, false)
  group.set_allows_action(defines.input_action.stack_split, false)
  group.set_allows_action(defines.input_action.stack_transfer, false)
  group.set_allows_action(defines.input_action.take_equipment, false)
  group.set_allows_action(defines.input_action.paste_entity_settings, false)
end

script.on_init(create_permission_group)
script.on_configuration_changed(create_permission_group)
