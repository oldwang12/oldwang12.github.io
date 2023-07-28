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
add_alias "cm" "kubectl get configmap"
add_alias "secret" "kubectl get secret"
add_alias "d" "kubectl delete po"
add_alias "dd" "kubectl --force delete po"

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

############################### 安装kubens、kubectx ###############################
read -p "是否安装 kubens、kubectx 执行？(y/n): " answer

write_to_file() {
    local file_path="$1"
    local line="$2"

    # 检查文件是否存在
    if [ -f "$file_path" ]; then
        # 检查要写入的内容是否已存在于文件中
        if grep -Fxq "$line" "$file_path"; then
            return 0  # 如果存在，则直接返回，不做写入操作
        fi
    fi

    # 将要写入的内容追加到文件末尾
    echo "$line" >> "$file_path"
    return 0
}

if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

    add_alias "ns" "kubens"
    add_alias "cc" "kubectx"
    
    #### 颜色
    write_to_file $BASHRC_FILE "export KUBECTX_CURRENT_FGCOLOR=\$(tput setaf 10)"
    write_to_file $BASHRC_FILE "export KUBECTX_CURRENT_BGCOLOR=\$(tput setab 0)"

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
else
    echo "退出"
    exit 0
fi