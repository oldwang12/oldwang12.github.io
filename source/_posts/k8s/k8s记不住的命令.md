---
layout: k8s
title: k8s记不住的命令
date: 2023-07-23 00:29:39
tags: k8s
---

#### 创建pod
```sh
kubectl run my-pod --image=nginx:latest
```
#### 更新镜像
```sh
kubectl set image deployment/provider provider=provider:latest
```

#### 给 node/pod 打标签
```sh
kubectl label nodes kube-node node=kube-node
```

#### 通过标签过滤
```sh
kubectl get node -l "node=kube-node"
```

#### kubectl cp
```sh
# 拷贝pod数据到本地
kubectl cp <some-namespace>/<some-pod>:/tmp/foo /tmp/foo

# 拷贝本地数据到pod之中
kubectl cp /tmp/foo <some-namespace>/<some-pod>:/tmp/foo
```

#### 回滚版本
```sh
# 查看历史版本
kubectl rollout history deployment provider

# 回滚到上一个版本
kubectl rollout undo deployment provider

# 回滚到指定版本
kubectl rollout undo deployment provider --to-revision=2
```

#### 污点
```sh
# <node-name> 是要添加污点的节点的名称。
# <taint-key> 是污点的键。
# <taint-value> 是污点的值，可以留空。
# <taint-effect> 是污点的影响效果，可以是以下选项之一：
# NoSchedule：表示不将新的Pod调度到有这个污点的节点上。
# PreferNoSchedule：表示尽量不将新的Pod调度到有这个污点的节点上。
# NoExecute：表示不将新的Pod调度到有这个污点的节点上，并且将已经运行在节点上的Pod驱逐出节点（如果它们不匹配Pod的容忍度）。
kubectl taint nodes <node-name> <taint-key>=<taint-value>:<taint-effect>
```

#### 探测
* livenessProbe: 存活探测
    * failureThreshold: 表示连续失败探测的次数，认为容器已经死亡，默认为3次
    * initialDelaySeconds: 表示在容器启动后多少秒开始进行探测，默认值为10秒。
    * periodSeconds: 表示多长时间重试一次探测，默认值为10秒
    * successThreshold: 表示连续成功探测的次数，认为容器仍处于健康状态，默认为1次
    * timeoutSeconds: 表示探测请求的超时时间，默认为1秒。
* readinessProbe: 就绪探测
```yaml
livenessProbe:
  failureThreshold: 10
  initialDelaySeconds: 300
  httpGet:
    path: /-/healthy
    port: web
    scheme: HTTP
  periodSeconds: 5
  successThreshold: 1
  timeoutSeconds: 3
readinessProbe:
  initialDelaySeconds: 300
  failureThreshold: 20
  httpGet:
    path: /-/ready
    port: web
    scheme: HTTP
  periodSeconds: 5
  successThreshold: 1
  timeoutSeconds: 3
```
