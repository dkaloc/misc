#!/bin/zsh

#
# Mouse Support.
#
# Authors:
#   Dusan Kaloc <dev@dusankaloc.net>
#

# TODO: focus + docs + non-prezto + support for non-xterm terminals

integer -g -r -H MOUSE_TOOLKIT_EVENT_ANY=0
integer -g -r -H MOUSE_TOOLKIT_EVENT_BUTTON_PRESSED=$((1 << 0))
integer -g -r -H MOUSE_TOOLKIT_EVENT_BUTTON_RELEASED=$((1 << 1))
integer -g -r -H MOUSE_TOOLKIT_EVENT_BUTTON_CLICKED=$((1 << 2))
integer -g -r -H MOUSE_TOOLKIT_EVENT_MOUSE_MOVED=$((1 << 3))
integer -g -r -H MOUSE_TOOLKIT_EVENT_MOUSE_DRAGGED=$((1 << 4))
integer -g -r -H MOUSE_TOOLKIT_EVENT_MOUSE_ENTERED=$((1 << 5))
integer -g -r -H MOUSE_TOOLKIT_EVENT_MOUSE_EXITED=$((1 << 6))
integer -g -r -H MOUSE_TOOLKIT_EVENT_WHEEL_SCROLLED=$((1 << 7))

integer -g -r -H MOUSE_TOOLKIT_SCROLL_DIRECTION_UPWARDS=0
integer -g -r -H MOUSE_TOOLKIT_SCROLL_DIRECTION_DOWNWARDS=1

integer -g -r -H MOUSE_TOOLKIT_MODIFIER_CTRL_DOWN_MASK=$((1 << 0))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_SHIFT_DOWN_MASK=$((1 << 1))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_META_DOWN_MASK=$((1 << 2))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_ALT_DOWN_MASK=$((1 << 3))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_ALT_GRAPH_DOWN_MASK=$((1 << 4))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_BUTTON1_DOWN_MASK=$((1 << 5))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_BUTTON2_DOWN_MASK=$((1 << 6))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_BUTTON3_DOWN_MASK=$((1 << 7))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_BUTTON4_DOWN_MASK=$((1 << 8))
integer -g -r -H MOUSE_TOOLKIT_MODIFIER_BUTTON5_DOWN_MASK=$((1 << 9))

integer -g -H MOUSE_TOOLKIT_EVENT
integer -g -H MOUSE_TOOLKIT_COLUMN
integer -g -H MOUSE_TOOLKIT_ROW
integer -g -H MOUSE_TOOLKIT_BUTTON
integer -g -H MOUSE_TOOLKIT_MODIFIERS
integer -g -H MOUSE_TOOLKIT_SCROLL_DIRECTION
integer -g -H MOUSE_TOOLKIT_CLICK_COUNT

typeset -g -A -H _MOUSE_TOOLKIT_HANDLERS=()
integer -g -H    _MOUSE_TOOLKIT_CAN_GENERATE_CLICK_EVENT
typeset -g -a -H _MOUSE_TOOLKIT_ESCSEQ_PARAMETERS
typeset -g -H    _MOUSE_TOOLKIT_ESCSEQ_SYMBOL

mouse_toolkit_enable_sgr_encoded_buttons_only_mode() {
  print -n '\e[?1000;1006h'
}
mouse_toolkit_disable_sgr_encoded_buttons_only_mode() {
  print -n '\e[?1000;1006l'
}

mouse_toolkit_enable_sgr_encoded_buttons_and_drag_mode() {
  print -n '\e[?1002;1006h'
}
mouse_toolkit_disable_sgr_encoded_buttons_and_drag_mode() {
  print -n '\e[?1002;1006l'
}

# Enables the XTerm's SGR-encoded 'Any-event' Mouse Tracking mode.
mouse_toolkit_enable_sgr_encoded_buttons_drag_and_move_mode() {
  print -n '\e[?1003;1006h'
}
# Disables the XTerm's SGR-encoded 'Any-event' Mouse Tracking mode.
mouse_toolkit_disable_sgr_encoded_buttons_drag_and_move_mode() {
  print -n '\e[?1003;1006l'
}

mouse-toolkit-start-listening-to-sgr-encoded-events-in-zle() {
  bindkey "\e[<" mouse-toolkit-handle-sgr-encoded-event
}
zle -N mouse-toolkit-start-listening-to-sgr-encoded-events-in-zle

mouse-toolkit-stop-listening-to-sgr-encoded-events-in-zle() {
  bindkey -r "\e[<"
}
zle -N mouse-toolkit-stop-listening-to-sgr-encoded-events-in-zle

_mouse-toolkit-zle-line-init() {
  zle _mouse-toolkit-original-zle-line-init
  $_MOUSE_TOOLKIT_ZLE_MOUSE_MODE_ENABLE_FCE
  zle mouse-toolkit-start-listening-to-sgr-encoded-events-in-zle
}
zle -N _mouse-toolkit-zle-line-init

_mouse-toolkit-zle-line-finish() {
  zle mouse-toolkit-stop-listening-to-sgr-encoded-events-in-zle
  $_MOUSE_TOOLKIT_ZLE_MOUSE_MODE_DISABLE_FCE
  zle _mouse-toolkit-original-zle-line-finish
}
zle -N _mouse-toolkit-zle-line-finish

_mouse_toolkit_install_zle_line_init_and_finish_handlers() {
  local mouse_mode
  zstyle -s ':prezto:module:mouse-toolkit' zle-mouse-mode mouse_mode

  case $mouse_mode in
  'buttons-only')
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_ENABLE_FCE='mouse_toolkit_enable_sgr_encoded_buttons_only_mode'
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_DISABLE_FCE='mouse_toolkit_disable_sgr_encoded_buttons_only_mode'
    ;;
  'buttons-and-drag')
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_ENABLE_FCE='mouse_toolkit_enable_sgr_encoded_buttons_and_drag_mode'
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_DISABLE_FCE='mouse_toolkit_disable_sgr_encoded_buttons_and_drag_mode'
    ;;
  'custom')
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_ENABLE_FCE=''
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_DISABLE_FCE=''
    ;;
  *)
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_ENABLE_FCE='mouse_toolkit_enable_sgr_encoded_buttons_drag_and_move_mode'
    _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_DISABLE_FCE='mouse_toolkit_disable_sgr_encoded_buttons_drag_and_move_mode'
    ;;
  esac

  zle -A zle-line-init _mouse-toolkit-original-zle-line-init
  zle -A _mouse-toolkit-zle-line-init zle-line-init

  zle -A zle-line-finish _mouse-toolkit-original-zle-line-finish
  zle -A _mouse-toolkit-zle-line-finish zle-line-finish
}

_mouse_toolkit_uninstall_zle_line_init_and_finish_handlers() {
  zle -A _mouse-toolkit-original-zle-line-init zle-line-init
  zle -A _mouse-toolkit-original-zle-line-finish zle-line-finish

  unset _MOUSE_TOOLKIT_ZLE_MOUSE_MODE_{ENABLE,DISABLE}_FCE
}

mouse_toolkit_handle_dired_button_event() {
  local ch row event_sgr_encoded

  read -k ch
  printf -v ch '%d' "'$ch"
  event_sgr_encoded+="${ch};"

  read -k 3 # ^X\eG

  read -k row
  printf -v row '%d' "'$row"
  ((row -= 32))

  read -k ch
  printf -v ch '%d' "'$ch"
  ((ch -= 32))

  event_sgr_encoded+="${ch};${row}"

  read -k ch
  event_sgr_encoded+="$ch"

  zle -U "$event_sgr_encoded"
  zle mouse-toolkit-handle-sgr-encoded-event
}
zle -N mouse-toolkit-handle-dired-button-event mouse_toolkit_handle_dired_button_event

# Handles an XTerm's SGR-encoded 'Any-event' Mouse Tracking mode event.
# Expects <bitmask>;<x-coord>;<y-coord><Mm> on stdin, where:
#   bitmask: 7 bits wide bitmask encoded as a series of ASCII digits.
#         Encodes both the mouse action and the keyboard modifiers pressed at the time the action occurred.
#         action: One of the following:
#           1) MOVE or DRAG action if the bit 5 (0x20) is set. Note: It is a mouse move if no button was previously pressed, mouse drag otherwise.
#           2) WHEEL action if the bit 6 (0x40) is set. The bit 0 then encodes direction. 0 for scroll up, 1 for scroll down.
#           3) BUTTON action otherwise. The bits 0 and 1 then encode the button, which was pressed or released. 00 for the left button, 01 for the middle and 10 for the right.
#         modifiers: Any combination of the following:
#           1) SHIFT pressed if the bit 2 (0x04) is set.
#           2) ALT/META pressed if the bit 3 (0x08) is set.
#           1) CTRL pressed if the bit 4 (0x10) is set.
#   x-coord: The X coordinate (i.e. column) of the cell the mouse currently points to.
#   y-coord: The Y coordinate (i.e. row) of the cell the mouse currently points to.
#   Mm: 'M' for button pressed, 'm' for button released. Only relevant for button actions.
mouse_toolkit_handle_sgr_encoded_event() {
  _mouse_toolkit_read_escape_sequence_without_csi

  integer bitmask=${_MOUSE_TOOLKIT_ESCSEQ_PARAMETERS[1]}
  MOUSE_TOOLKIT_BUTTON=-1

  if ((bitmask & 0x20 != 0)); then
    if ((MOUSE_TOOLKIT_MODIFIERS < MOUSE_TOOLKIT_MODIFIER_BUTTON1_DOWN_MASK)); then
      MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_MOUSE_MOVED
    else
      MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_MOUSE_DRAGGED
    fi
    _MOUSE_TOOLKIT_CAN_GENERATE_CLICK_EVENT=0
  elif ((bitmask & 0x40 != 0)); then
    MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_WHEEL_SCROLLED
    MOUSE_TOOLKIT_SCROLL_DIRECTION=$((bitmask & 0x01))
  else
    MOUSE_TOOLKIT_BUTTON=$(((bitmask & 0x03) + 1))
    integer button_mask=$((MOUSE_TOOLKIT_MODIFIER_BUTTON1_DOWN_MASK << (MOUSE_TOOLKIT_BUTTON - 1)))

    if [[ "$_MOUSE_TOOLKIT_ESCSEQ_SYMBOL" == 'M' ]]; then
      MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_BUTTON_PRESSED
      ((MOUSE_TOOLKIT_MODIFIERS |= button_mask))
      _MOUSE_TOOLKIT_CAN_GENERATE_CLICK_EVENT=1
    else
      MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_BUTTON_RELEASED
      ((MOUSE_TOOLKIT_MODIFIERS &= ~button_mask))
    fi
  fi

  MOUSE_TOOLKIT_COLUMN=${_MOUSE_TOOLKIT_ESCSEQ_PARAMETERS[2]}
  MOUSE_TOOLKIT_ROW=${_MOUSE_TOOLKIT_ESCSEQ_PARAMETERS[3]}

  _mouse_toolkit_update_modifier \
    $((bitmask & 0x04)) $MOUSE_TOOLKIT_MODIFIER_SHIFT_DOWN_MASK

  if zstyle -t ':prezto:module:mouse-toolkit' use-meta-instead-of-alt; then
    local altOrMetaMod=$MOUSE_TOOLKIT_MODIFIER_META_DOWN_MASK
  else
    local altOrMetaMod=$MOUSE_TOOLKIT_MODIFIER_ALT_DOWN_MASK
  fi
  _mouse_toolkit_update_modifier \
    $((bitmask & 0x08)) $altOrMetaMod

  _mouse_toolkit_update_modifier \
    $((bitmask & 0x10)) $MOUSE_TOOLKIT_MODIFIER_CTRL_DOWN_MASK

  mouse_toolkit_fire_handlers
}
zle -N mouse-toolkit-handle-sgr-encoded-event mouse_toolkit_handle_sgr_encoded_event

_mouse_toolkit_update_modifier() {
  if (( $1 )); then
    ((MOUSE_TOOLKIT_MODIFIERS |= $2))
  else
    ((MOUSE_TOOLKIT_MODIFIERS &= ~$2))
  fi
}

mouse_toolkit_add_handler() {
  mouse_toolkit_remove_handler "$1" "$2"
  _MOUSE_TOOLKIT_HANDLERS+=("$1" "${_MOUSE_TOOLKIT_HANDLERS[$1]} $2")
}

mouse_toolkit_remove_handler() {
  _MOUSE_TOOLKIT_HANDLERS+=("$1" "${_MOUSE_TOOLKIT_HANDLERS[$1]/ $2}")
}

mouse_toolkit_fire_handlers() {
  MOUSE_TOOLKIT_CLICK_COUNT=0
  mouse_toolkit_fire_handlers_for_event $MOUSE_TOOLKIT_EVENT
  mouse_toolkit_fire_handlers_for_event $MOUSE_TOOLKIT_EVENT_ANY

  if ((_MOUSE_TOOLKIT_CAN_GENERATE_CLICK_EVENT &&
        MOUSE_TOOLKIT_EVENT == MOUSE_TOOLKIT_EVENT_BUTTON_RELEASED)); then

    MOUSE_TOOLKIT_EVENT=$MOUSE_TOOLKIT_EVENT_BUTTON_CLICKED
    MOUSE_TOOLKIT_CLICK_COUNT=1

    mouse_toolkit_fire_handlers_for_event $MOUSE_TOOLKIT_EVENT
    mouse_toolkit_fire_handlers_for_event $MOUSE_TOOLKIT_EVENT_ANY
  fi
}

mouse_toolkit_fire_handlers_for_event() {
  local handler
  for handler in ${=_MOUSE_TOOLKIT_HANDLERS[$1]}; do
    $handler
  done
}

mouse_toolkit_debug_event() {
  case $MOUSE_TOOLKIT_EVENT in
    $MOUSE_TOOLKIT_EVENT_BUTTON_PRESSED)
      echo -En 'BUTTON_PRESSED';;
    $MOUSE_TOOLKIT_EVENT_BUTTON_RELEASED)
      echo -En 'BUTTON_RELEASED';;
    $MOUSE_TOOLKIT_EVENT_BUTTON_CLICKED)
      echo -En 'BUTTON_CLICKED';;
    $MOUSE_TOOLKIT_EVENT_MOUSE_MOVED)
      echo -En 'MOUSE_MOVED';;
    $MOUSE_TOOLKIT_EVENT_MOUSE_DRAGGED)
      echo -En 'MOUSE_DRAGGED';;
    $MOUSE_TOOLKIT_EVENT_MOUSE_ENTERED)
      echo -En 'MOUSE_ENTERED';;
    $MOUSE_TOOLKIT_EVENT_MOUSE_EXITED)
      echo -En 'MOUSE_EXITED';;
    $MOUSE_TOOLKIT_EVENT_WHEEL_SCROLLED)
      echo -En 'WHEEL_SCROLLED';;
    *)
      echo -En 'unknown type';;
  esac

  echo -En ",(col=${MOUSE_TOOLKIT_COLUMN},row=${MOUSE_TOOLKIT_ROW})"

  if ((MOUSE_TOOLKIT_EVENT < MOUSE_TOOLKIT_EVENT_MOUSE_MOVED)); then
    echo -En ",button=$MOUSE_TOOLKIT_BUTTON"

    ((MOUSE_TOOLKIT_EVENT == MOUSE_TOOLKIT_EVENT_BUTTON_CLICKED)) &&
      echo -En ",clickCount=$MOUSE_TOOLKIT_CLICK_COUNT"
  fi

  if ((MOUSE_TOOLKIT_EVENT == MOUSE_TOOLKIT_EVENT_WHEEL_SCROLLED)); then
    echo -En ",scrollDirection="
    if ((MOUSE_TOOLKIT_SCROLL_DIRECTION == MOUSE_TOOLKIT_SCROLL_DIRECTION_UPWARDS)); then
      echo -En "upwards"
    else
      echo -En "downwards"
    fi
  fi

  if ((MOUSE_TOOLKIT_MODIFIERS != 0)); then
    echo -En ",modifiers="
    local modifiers=''

    ((MOUSE_TOOLKIT_MODIFIER_CTRL_DOWN_MASK & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
      modifiers+="Ctrl+"
    ((MOUSE_TOOLKIT_MODIFIER_SHIFT_DOWN_MASK & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
      modifiers+="Shift+"
    ((MOUSE_TOOLKIT_MODIFIER_META_DOWN_MASK & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
      modifiers+="Meta+"
    ((MOUSE_TOOLKIT_MODIFIER_ALT_DOWN_MASK & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
      modifiers+="Alt+"
    ((MOUSE_TOOLKIT_MODIFIER_ALT_GRAPH_DOWN_MASK & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
      modifiers+="Alt Graph+"

    for ((i = 0; i < 16; i++)); do
      (((MOUSE_TOOLKIT_MODIFIER_BUTTON1_DOWN_MASK << i) & MOUSE_TOOLKIT_MODIFIERS != 0)) &&
        modifiers+="Button$((i + 1))+"
    done

    echo -En "${modifiers:0:-1}"
  fi

  echo ''
}

_mouse_toolkit_read_escape_sequence() {
  read -k 2 && _mouse_toolkit_read_escape_sequence_without_csi
}

_mouse_toolkit_read_escape_sequence_without_csi() {
  _MOUSE_TOOLKIT_ESCSEQ_PARAMETERS=()
  _MOUSE_TOOLKIT_ESCSEQ_SYMBOL=''

  local char param
  while true; do
    param=''
    read -k char
    while [[ $char == [0-9] ]]; do
      param+=$char
      read -k char
    done
    _MOUSE_TOOLKIT_ESCSEQ_PARAMETERS+=("$param")
    if [[ $char != ';' ]]; then
      _MOUSE_TOOLKIT_ESCSEQ_SYMBOL="$char"
      break
    fi
  done
}

if zstyle -t ':prezto:module:mouse-toolkit' capture-mouse-in-zle; then
  _mouse_toolkit_install_zle_line_init_and_finish_handlers
fi
