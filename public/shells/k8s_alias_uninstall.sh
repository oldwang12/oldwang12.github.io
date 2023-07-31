#!/bin/bash
BASHRC_FILE="$HOME/.bashrc"

if [ "$1" != "" ]; then
  BASHRC_FILE=$1
fi

remove_alias() {
  if [[ -f "$BASHRC_FILE" ]]; then
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
      if [[ ! "$line" =~ ^alias\ (k|kk|kl|kd|p|dp|sts|svc|no|pvc|sa|ds|rs|ep|cm|secret|d|dd|ke|kh)= ]]; then
        echo "$line" >> "$temp_file"
      fi
    done < "$BASHRC_FILE"

    cp "$temp_file" "$BASHRC_FILE"
    rm "$temp_file"
  fi
}

remove_alias
rm -f $HOME/.shell/k8s_exec_pod.sh