#!/bin/bash

BASHRC_FILE="$HOME/.bashrc"

#!/bin/bash

print_green() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo -e "${GREEN}$1${NC}"
}

#!/bin/bash

print_red() {
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "${RED}$1${NC}"
}


#!/bin/bash

print_yellow() {
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}$1${NC}"
}

add_alias_k() {
   #!/bin/bash

    LINE="alias $1=\"${2}\""
    
    if ! grep -q "$LINE" "$BASHRC_FILE"; then
        echo $LINE >> "$BASHRC_FILE"
        print_green "Added alias $LINE to $BASHRC_FILE"
    else
        print_yellow "Alias $1 already exists in $BASHRC_FILE"
    fi
}

add_alias_k "k" "kubectl"
add_alias_k "kk" "kubectl -n kube-system"
add_alias_k "kl" "kubectl logs -f"
add_alias_k "kd" "kubectl describe"
add_alias_k "p" "kubectl get po"
add_alias_k "svc" "kubectl get svc"
add_alias_k "no" "kubectl get no"
add_alias_k "pvc" "kubectl get pvc"
add_alias_k "sa" "kubectl get sa"
add_alias_k "ds" "kubectl get ds"
add_alias_k "rs" "kubectl get rs"
add_alias_k "ep" "kubectl get ep"

source "$BASHRC_FILE"
