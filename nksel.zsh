#!/bin/zsh

#
# Natural Keyboard Selection in ZLE.
#
# Authors:
#   Dusan Kaloc <dev@dusankaloc.net>
#

nksel-has-selection() {
  (( REGION_ACTIVE == 1 &&
     MARK != CURSOR ))
}
zle -N nksel-has-selection

nksel-start-or-continue-selecting() {
  zle nksel-has-selection ||
     zle nksel-start-selecting
}
zle -N nksel-start-or-continue-selecting

nksel-start-selecting() {
  (( MARK = CURSOR,
     REGION_ACTIVE = 1 ))

  zstyle -t ':prezto:module:nksel' keep-previous-highlights ||
    unset region_highlight
}
zle -N nksel-start-selecting

nksel-end-selecting() {
  (( REGION_ACTIVE = 0,
     MARK = CURSOR ))
}
zle -N nksel-end-selecting

nksel-select-all() {
  (( MARK = 0,
     CURSOR = $#BUFFER ))
}
zle -N nksel-select-all

nksel-copy-selection() {
  zle copy-region-as-kill

  local selection

  if [[ "$(locale charmap)" != 'UTF-8' ]]; then
    selection=$(echo -En "$CUTBUFFER" | iconv -c -t 'UTF-8//TRANSLIT')
  else
    selection="$CUTBUFFER"
  fi

  if zstyle -t ':prezto:module:nksel' use-crlf-line-endings; then
    local crlf=$'\r\n'
    selection="${selection//$'\n'/$crlf}"
  fi

  echo -en "\e]52;c;$(echo -En "$selection" | base64)\a"
}
zle -N nksel-copy-selection

nksel-copy-selection-or-interrupt-on-ctrl-c() {
  if zle nksel-has-selection; then
    zle nksel-copy-selection
    zle nksel-end-selecting
    zle recursive-edit
  fi
}
zle -N nksel-copy-selection-or-interrupt-on-ctrl-c

nksel-delete-selection() {
  zle kill-region
}
zle -N nksel-delete-selection

nksel-cut-selection() {
  nksel-copy-selection
  nksel-delete-selection
}
zle -N nksel-cut-selection

nksel_start_or_continue_selecting_on() {
  if zle -l "nksel-pre-$2"; then
    2="nksel-pre-$2"
  fi
  function "nksel-start-$2" {
    zle nksel-start-or-continue-selecting
    zle "${funcstack[1]/nksel-start-/}"

    zstyle -t ':prezto:module:nksel' copy-on-select &&
      zle nksel-copy-selection
  }
  zle -N "nksel-start-$2"
  bindkey "$1" "nksel-start-$2"
}

_nksel_redefine_widget() {
  zle -A "$1" "nksel-pre-$1"
  zle -N "nksel-post-$1"
  zle -A "nksel-post-$1" "$1"
}

nksel_copy_selection_or_execute_on() {
  function "nksel-post-$1" {
    if zle nksel-has-selection; then
      zle nksel-copy-selection
      zle nksel-end-selecting
    else
      zle nksel-end-selecting
      zle "${funcstack[1]/post/pre}"
    fi
  }
  _nksel_redefine_widget "$1"
}

nksel_copy_selection_and_execute_on() {
  function "nksel-post-$1" {
    zle nksel-copy-selection
    zle nksel-end-selecting
    zle "${funcstack[1]/post/pre}"
  }
  _nksel_redefine_widget "$1"
}

nksel_clear_selection_or_execute_on() {
  function "nksel-post-$1" {
    zle nksel-end-selecting
    if ! zle nksel-has-selection; then
      zle "${funcstack[1]/post/pre}"
    fi
  }
  _nksel_redefine_widget "$1"
}

nksel_clear_selection_and_execute_on() {
  function "nksel-post-$1" {
    zle nksel-end-selecting
    zle "${funcstack[1]/post/pre}"
  }
  _nksel_redefine_widget "$1"
}

nksel_delete_selection_or_execute_on() {
  function "nksel-post-$1" {
    if zle nksel-has-selection; then
      zle nksel-delete-selection
      zle nksel-end-selecting
    else
      zle nksel-end-selecting
      zle "${funcstack[1]/post/pre}"
    fi
  }
  _nksel_redefine_widget "$1"
}

nksel_delete_selection_and_execute_on() {
  function "nksel-post-$1" {
    if zle nksel-has-selection; then
      zle nksel-delete-selection
    fi
    zle nksel-end-selecting
    zle "${funcstack[1]/post/pre}"
  }
  _nksel_redefine_widget "$1"
}

nksel_delete_selection_and_execute_on_noarg_call() {
  function "nksel-post-$1" {
    if [[ $ARGC -eq 0 ]] && zle nksel-has-selection; then
      zle nksel-delete-selection
    fi
    zle nksel-end-selecting
    zle "${funcstack[1]/post/pre}"
  }
  _nksel_redefine_widget "$1"
}

local -a _widgets
local _widget

  zstyle -a ':prezto:module:nksel' copy-selection-or-execute-on _widgets
  for _widget in $_widgets; do
    nksel_copy_selection_or_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' copy-selection-and-execute-on _widgets
  for _widget in $_widgets; do
    nksel_copy_selection_and_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' clear-selection-or-execute-on _widgets
  for _widget in $_widgets; do
    nksel_clear_selection_or_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' clear-selection-and-execute-on _widgets
  for _widget in $_widgets; do
    nksel_clear_selection_and_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' delete-selection-or-execute-on _widgets
  for _widget in $_widgets; do
    nksel_delete_selection_or_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' delete-selection-and-execute-on _widgets
  for _widget in $_widgets; do
    nksel_delete_selection_and_execute_on "$_widget"
  done

  zstyle -a ':prezto:module:nksel' delete-selection-and-execute-on-noarg-call _widgets
  for _widget in $_widgets; do
    nksel_delete_selection_and_execute_on_noarg_call "$_widget"
  done

unset _widget{,s}

local -A _bindings
local _key

  zstyle -a ':prezto:module:nksel' start-or-continue-selecting-on _bindings
  for _key in "${(k)_bindings[@]}"; do
    nksel_start_or_continue_selecting_on "$_key" "$_bindings[$_key]"
  done

  zstyle -a ':prezto:module:nksel' bindkey _bindings
  for _key in "${(k)_bindings[@]}"; do
    bindkey "$_key" "nksel-$_bindings[$_key]"
  done

unset _bindings _key
