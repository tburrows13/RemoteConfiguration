data:extend{
  {
    type = "custom-input",
    name = "rc-open-gui",
    key_sequence = "",
    linked_game_control = "open-gui",
  },
  {
    type = "custom-input",
    name = "rc-paste-entity-settings",
    key_sequence = "",
    linked_game_control = "paste-entity-settings",
  },
  {
    type = "custom-input",
    name = "rc-build",
    key_sequence = "",
    linked_game_control = "build",
  },
  {
    type = "custom-input",
    name = "rc-rotate",
    key_sequence = "",
    linked_game_control = "rotate",
  },
  {
    type = "custom-input",
    name = "rc-reverse-rotate",
    key_sequence = "",
    linked_game_control = "reverse-rotate",
  },
  {
    type = "custom-input",
    name = "rc-mine",
    key_sequence = "",
    linked_game_control = "mine",
  },
  {
    type = "custom-input",
    name = "rc-shift-right-click",
    key_sequence = "",
    linked_game_control = "editor-remove-scripting-object",
  },
  {
    type = "tips-and-tricks-item-category",
    name = "remote-configuration",
    order = "l-[rc]",
  },
  {
    type = "tips-and-tricks-item",
    name = "rc-introduction",
    category = "remote-configuration",
    order = "a",
    is_title = true,
    trigger = {
      type = "time-elapsed",
      ticks = 60 * 60 * 10 -- 10 minutes
    },
  },
}
