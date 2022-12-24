-- These entity types can be opened remotely anyway
local entity_type_blacklist = {
  ["locomotive"] = true,
  ["train-stop"] = true,
  ["electric-pole"] = true,
}

script.on_event("rc-open-gui",
  function(event)
    local player = game.get_player(event.player_index)
    local selected = player.selected

    if selected then
      if entity_type_blacklist[selected.type] then return end
      reset_player(player)  -- Ensures that can_reach_entity is accurate
      local out_of_reach = not player.can_reach_entity(selected)
      local map_mode = player.render_mode == defines.render_mode.chart_zoomed_in
      if out_of_reach or map_mode then
        player.opened = nil  -- Triggers on_gui_closed before we open the GUI we care about
        if out_of_reach then
          if player.character and player.character_reach_distance_bonus < 200000 then
            player.character_reach_distance_bonus = player.character_reach_distance_bonus + 200000
          end
          player.permission_group = game.permissions.get_group("Remote Configuration GUI opened")
        end
        player.opened = selected
        if player.opened_gui_type ~= defines.gui_type.entity then
          -- Opening GUI failed
          reset_player(player)
        end
      end
    end
  end
)

function reset_player(player)
  player.permission_group = game.permissions.get_group("Default")
  if not player.character then return end
  while player.character_reach_distance_bonus >= 200000 do
    player.character_reach_distance_bonus = player.character_reach_distance_bonus - 200000
  end
end
script.on_event(defines.events.on_gui_closed,
  function(event)
    local player = game.get_player(event.player_index)
    reset_player(player)
  end
)

local function create_permission_group()
  local permissions = game.permissions
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
  group.set_allows_action(defines.input_action.drop_item, false)
  group.set_allows_action(defines.input_action.fast_entity_split, false)
  group.set_allows_action(defines.input_action.fast_entity_transfer, false)
  group.set_allows_action(defines.input_action.inventory_split, false)
  group.set_allows_action(defines.input_action.inventory_transfer, false)
  group.set_allows_action(defines.input_action.open_item, false)  -- ?
  group.set_allows_action(defines.input_action.open_mod_item, false)  -- ?
  group.set_allows_action(defines.input_action.open_parent_of_opened_item, false)  -- ?
  group.set_allows_action(defines.input_action.place_equipment, false)
  group.set_allows_action(defines.input_action.stack_split, false)
  group.set_allows_action(defines.input_action.stack_transfer, false)
  group.set_allows_action(defines.input_action.take_equipment, false)

end

script.on_init(create_permission_group)
script.on_configuration_changed(create_permission_group)
