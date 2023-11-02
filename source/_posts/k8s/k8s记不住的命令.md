---
layout: k8s
title: k8s记不住的命令
date: 2023-07-23 00:29:39
tags: k8s
categories: k8s
---

{% note primary%}
懒人笔记
{% endnote %}


<!-- more -->
## 1. 创建pod
```sh
kubectl run my-pod --image=nginx:latest
```
## 2. 更新镜像
```sh
kubectl set image deployment/provider provider=provider:latest
```


## 3. scale
```sh
kubectl scale deployment/provider --replicas=0
```

或者

```sh
kubectl scale deployment my-deployment --replicas=0
```

## 4. 给 node/pod 打标签
```sh
kubectl label nodes kube-node node=kube-node
```

## 5. 通过标签过滤
```sh
kubectl get node -l "node=kube-node"
```

## 6. cp

### 6.1. 6.1 拷贝pod数据到本地

```sh
kubectl cp <some-namespace>/<some-pod>:/tmp/foo /tmp/foo
```

### 6.2. 6.2 拷贝本地数据到pod之中

```sh
kubectl cp /tmp/foo <some-namespace>/<some-pod>:/tmp/foo
```

## 7. 查看支持的 apiVersion
```sh
kubectl api-versions
```

## 8. 回滚版本
```sh
# 重启pod
kubectl rollout restart deployment nginx

# 查看历史版本
kubectl rollout history deployment nginx

# 回滚到上一个版本
kubectl rollout undo deployment nginx

# 回滚到指定版本
kubectl rollout undo deployment nginx --to-revision=2
```

## 9. 污点
```sh
kubectl taint nodes <node-name> <taint-key>=<taint-value>:<taint-effect>
```

{% note warning %}
`<node-name>` 是要添加污点的节点的名称。
`<taint-key>` 是污点的键。
`<taint-value>` 是污点的值，可以留空。
`<taint-effect>` 是污点的影响效果，可以是以下选项之一：
- NoSchedule：表示不将新的Pod调度到有这个污点的节点上。
- PreferNoSchedule：表示尽量不将新的Pod调度到有这个污点的节点上。
- NoExecute：表示不将新的Pod调度到有这个污点的节点上，并且将已经运行在节点上的Pod驱逐出节点（如果它们不匹配Pod的容忍度）。
{% endnote %}


## 10. 探测
### 10.1. 10.1 livenessProbe: 存活探测
* **failureThreshold**: 表示连续失败探测的次数，认为容器已经死亡，默认为3次
* **initialDelaySeconds**: 表示在容器启动后多少秒开始进行探测，默认值为10秒。
* **periodSeconds**: 表示多长时间重试一次探测，默认值为10秒
* **successThreshold**: 表示连续成功探测的次数，认为容器仍处于健康状态，默认为1次
* **timeoutSeconds**: 表示探测请求的超时时间，默认为1秒。
### 10.2. 10.2 readinessProbe: 就绪探测
  
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

## 11. 进入pod命名空间
### 11.1. 找到 pod 所在节点
```sh
k get po -owide

ssh root@xx.xx.xx.xx
```

### 11.2. 获取容器 pid

```sh
# docker
docker inspect --format '{{ .State.Pid }}' 容器名/ID

# containerd
crictl inspect 容器ID | grep pid
```

### 11.3. 进入容器网络
```sh
nsenter -t $PID -n
```

### 11.4. 更改grafana密码
```sh
grafana-cli admin reset-admin-password <password>
```

### 11.5. 生成 hub secret

```sh
kubectl create secret docker-registry <secret_name> \
  --docker-server=<registry_url> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>
```

k create secret docker-registry hub-aliyun \
  --docker-server=registry.cn-hangzhou.aliyuncs.com \
  --docker-username=w17691027323 \
  --docker-password=wang970425

## 12. 默认集群svc域名
```sh
dig @172.17.0.2 kubernetes.default.svc.cluster.local
```