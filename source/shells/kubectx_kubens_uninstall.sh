#!/bin/bash
BASHRC_FILE="$HOME/.bashrc"

if [ "$1" != "" ]; then
  BASHRC_FILE=$1
fi

print_green() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo -e "${GREEN}$1${NC}"
}

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

print_green 如果你卸载成功了，重新source后，发现kubectl快捷命令继续可以使用。此时终端重新连接即可。