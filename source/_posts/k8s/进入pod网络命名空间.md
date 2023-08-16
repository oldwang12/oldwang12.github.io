---
layout: k8s
title: 进入pod网络命名空间
date: 2023-08-03 16:35:39
tags: k8s
categories: k8s
---

#### 1. 找到 pod 所在节点
```sh
k get po -owide

ssh root@xx.xx.xx.xx
```

#### 2. 获取容器 pid

```sh
# docker
docker inspect --format '{{ .State.Pid }}' 容器名/ID

# containerd
crictl inspect 容器ID | grep pid
```

#### 3. 进入容器网络
```sh
nsenter -t $PID -n
```