#!/bin/bash
BASHRC_FILE="$HOME/.bashrc"

if [ "$1" != "" ]; then
  BASHRC_FILE=$1
fi

remove_alias() {
  if [[ -f "$BASHRC_FILE" ]]; then
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
      if [[ ! "$line" =~ ^alias\ (ns|cc)= ]]; then
        echo "$line" >> "$temp_file"
      fi
    done < "$BASHRC_FILE"

    cp "$temp_file" "$BASHRC_FILE"
    rm "$temp_file"
  fi
}

remove_alias