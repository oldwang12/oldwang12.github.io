# 安装kubens、kubectx
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

sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

add_alias "ns" "kubens"
add_alias "cc" "kubectx"

# 颜色
write_to_file $BASHRC_FILE "export KUBECTX_CURRENT_FGCOLOR=\$(tput setaf 10)"
write_to_file $BASHRC_FILE "export KUBECTX_CURRENT_BGCOLOR=\$(tput setab 0)"

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install