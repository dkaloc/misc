#!/bin/zsh

#
# Place text cursor closest to a visual cell in ZLE.
#
# Authors:
#   Dusan Kaloc <dev@dusankaloc.net>
#

# TODO: docs + non-prezto + support for non-xterm terminals + handle signals

integer -g -H ZLE_CURSOR_PLACEMENT_CURSOR_COLUMN
integer -g -H ZLE_CURSOR_PLACEMENT_CURSOR_ROW

typeset -g -a -H _ZLE_CURSOR_PLACEMENT_ESCSEQ_PARAMETERS
typeset -g -H    _ZLE_CURSOR_PLACEMENT_ESCSEQ_SYMBOL

zle-cursor-placement-place-cursor-to-cell() {
  print -n '\e[?25l' # Hide Cursor

  integer cell_column=$1
  integer cell_row=$2

  ((CURSOR=0))
  zle -R
  zle_cursor_placement_read_cursor_position
  if ((cell_row < ZLE_CURSOR_PLACEMENT_CURSOR_ROW)); then
    ((cell_row = ZLE_CURSOR_PLACEMENT_CURSOR_ROW))
  fi

  ((CURSOR=$#BUFFER))
  zle -R
  zle_cursor_placement_read_cursor_position
  if ((cell_row > ZLE_CURSOR_PLACEMENT_CURSOR_ROW)); then
    ((cell_row = ZLE_CURSOR_PLACEMENT_CURSOR_ROW))
  fi

  integer low=0 mid high=$(($#BUFFER + 1))

  for ((;low <= high;)); do
    ((mid = (low + high) / 2))

    ((CURSOR = mid))
    zle -R
    zle_cursor_placement_read_cursor_position

    if ((cell_row < ZLE_CURSOR_PLACEMENT_CURSOR_ROW)); then
      ((cmp = +1))
    elif ((cell_row > ZLE_CURSOR_PLACEMENT_CURSOR_ROW)); then
      ((cmp = -1))
    elif ((cell_column < ZLE_CURSOR_PLACEMENT_CURSOR_COLUMN)); then
      ((cmp = +1))
    elif ((cell_column > ZLE_CURSOR_PLACEMENT_CURSOR_COLUMN)); then
      ((cmp = -1))
    else
      ((cmp = 0))
    fi

    if ((cmp < 0)); then
      ((low = mid + 1))
    elif ((cmp > 0)); then
      ((high = mid - 1))
    else
      ((low = mid + 1))
      break
    fi
  done
  ((CURSOR = low - 1))
  
  print -n '\e[?25h' # Show Cursor
}
zle -N zle-cursor-placement-place-cursor-to-cell

zle_cursor_placement_read_cursor_position() {
  print -n '\e[6n'
  _zle_cursor_placement_read_escape_sequence
  ZLE_CURSOR_PLACEMENT_CURSOR_ROW=${_ZLE_CURSOR_PLACEMENT_ESCSEQ_PARAMETERS[1]}
  ZLE_CURSOR_PLACEMENT_CURSOR_COLUMN=${_ZLE_CURSOR_PLACEMENT_ESCSEQ_PARAMETERS[2]}
}

_zle_cursor_placement_read_escape_sequence() {
  _ZLE_CURSOR_PLACEMENT_ESCSEQ_PARAMETERS=()
  _ZLE_CURSOR_PLACEMENT_ESCSEQ_SYMBOL=''

  read -s -k 2 # \e[
  
  local char param
  while true; do
    param=''
    read -s -k char
    while [[ $char == [0-9] ]]; do
      param+=$char
      read -s -k char
    done
    _ZLE_CURSOR_PLACEMENT_ESCSEQ_PARAMETERS+=("$param")
    if [[ $char != ';' ]]; then
      _ZLE_CURSOR_PLACEMENT_ESCSEQ_SYMBOL="$char"
      break
    fi
  done
}
