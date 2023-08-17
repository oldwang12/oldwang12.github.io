---
layout: k8s
title: 安装kubectl快捷命令
date: 2023-07-23 15:12:24
tags: [kubectl,alias,k8s]
categories: k8s
---

## 1. 简介

{% note success %}
k8s 的命令不长，也很好记，但身为一个偷懒者，我想我可以更简洁、高效。

默认快捷命令保存在 ~/.bashrc 文件。
{% endnote %}
## 2. 安装

你可以通过该命令一键安装

```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/k8s_alias_install.sh | sh -
```

如果你的环境默认并不是 {% label primary @~/.bashrc %}，可以通过下面的命令

```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/k8s_alias_install.sh | bash -s ~/.zshrc
```

执行完记得 {% label primary @source <～/FILE_NAME> %}，例如：

```
source ~/.bashrc
```

## 3. 测试

```sh
# 获取pod
$ p
NAME                              READY   STATUS    RESTARTS   AGE
test-deployment-d5b769945-q29d4   1/1     Running   0          6d7h

# 进入pod
$ ke test-deployment-d5b769945-q29d4
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.

# 查看日志
$ kl

# 查看帮助
$ kh
alias k="kubectl"
alias kk="kubectl -n kube-system"
alias kl="kubectl logs -f"
alias kd="kubectl describe"
alias p="kubectl get po"
alias svc="kubectl get svc"
alias no="kubectl get no"
alias pvc="kubectl get pvc"
alias sa="kubectl get sa"
alias ds="kubectl get ds"
alias rs="kubectl get rs"
alias ep="kubectl get ep"
ke=kubectl exec -it POD_NAME sh
```

{% note primary %}
至此，已经完成了设置kubectl快捷命令。如果你没有多集群切换需求或者关于namespace高效切换，那么到这里就结束了。
{% endnote %}

## 4. 卸载
```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/k8s_alias_uninstall.sh | sh -
```

如果你的文件不是 ~/.bashrc，需要替换为对应文件，以 ~/.zshrc 为例

```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/k8s_alias_uninstall.sh | bash -s ~/.zshrc
```

执行完记得 {% label primary @source <～/FILE_NAME> %}，例如：

```
source ~/.bashrc
```

## 5. kubens、kubectx

### 5.1 安装
安装脚本
```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/kubectx_kubens_install.sh | sh -
```

你可以通过修改对应文件更改 fzf 的背景颜色和字体颜色

```sh
# vim ~/.bashrc
# 颜色对照表参考: https://github.com/medikoo/cli-color
export KUBECTX_CURRENT_FGCOLOR=$(tput setaf 6) # blue text
export KUBECTX_CURRENT_BGCOLOR=$(tput setab 7) # white background
```
### 5.2 卸载
```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/kubectx_kubens_uninstall.sh | sh -
```

如果你的文件不是 ~/.bashrc，需要替换为对应文件，以 ~/.zshrc 为例

```sh
curl -sfL https://raw.githubusercontent.com/oldwang12/oldwang12.github.io/master/source/shells/kubectx_kubens_uninstall.sh | bash -s ~/.zshrc
```

执行完记得 {% label primary @source <～/FILE_NAME> %}，例如：

```
source ~/.bashrc
```