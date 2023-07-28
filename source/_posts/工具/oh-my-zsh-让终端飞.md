---
layout: 工具
title: oh my zsh 让终端飞
date: 2023-07-27 18:31:40
tags: 工具
---


```sh
# yum先安装，如果是ubuntu使用 apt-get install zsh 
yum -y install zsh

# 安装脚本
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 插件安装

## 高亮插件
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

## 自动补全
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
```


#### 手动更改插件配置
```sh
$ vim ~/.zshrc

# plugins 更改如下
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# 更换主题
ZSH_THEME="ys"

# 重新加载
source ~/.zshrc
```