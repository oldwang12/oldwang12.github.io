#!/bin/bash
BASHRC_FILE="$HOME/.bash_profile"

if [ "$1" != "" ]; then
  BASHRC_FILE=$1
fi

print_green() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo -e "${GREEN}$1${NC}"
}

print_yellow() {
  YELLOW='\033[0;33m'
  NC='\033[0m'
  echo -e "${YELLOW}$1${NC}"
}

add_alias() {
    LINE="alias $1=\"${2}\""
    if ! grep -q "$LINE" "$BASHRC_FILE"; then
        echo $LINE >> "$BASHRC_FILE"
        print_green "Added alias $LINE to $BASHRC_FILE"
    else
        print_yellow "Alias $1 already exists in $BASHRC_FILE"
    fi
}

add_alias "k" "kubectl"
add_alias "kk" "kubectl -n kube-system"
add_alias "kl" "kubectl logs -f"
add_alias "kd" "kubectl describe"
add_alias "p" "kubectl get po"
add_alias "dp" "kubectl get deployment"
add_alias "sts" "kubectl get sts"
add_alias "svc" "kubectl get svc"
add_alias "no" "kubectl get no"
add_alias "pvc" "kubectl get pvc"
add_alias "sa" "kubectl get sa"
add_alias "ds" "kubectl get ds"
add_alias "rs" "kubectl get rs"
add_alias "ep" "kubectl get ep"

shell_dir=$HOME/.shell
mkdir -p $shell_dir

content='kubectl exec -it $1 sh'
cat <<EOF > $shell_dir/k8s_exec_pod.sh
$content
EOF
chmod +x $shell_dir/k8s_exec_pod.sh
add_alias "ke" "$shell_dir/k8s_exec_pod.sh"

echo_str='alias ke=kubectl exec -it $1 sh'
add_alias "kh" "cat $BASHRC_FILE | grep -v kh | grep kubectl && echo $echo_str"