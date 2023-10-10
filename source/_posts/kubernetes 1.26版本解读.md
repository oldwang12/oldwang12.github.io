---
title: kubernetes 1.26版本解读
category: k8s
date: 2023-09-06 14:25:28
updated:
tags:
---

<!-- more -->

# 1. 重大变化

## 1.1 containerd

1.26 不支持 CRI v1alpha2，并且要求容器运行时必须支持 CRI v1。因此必须要求 Containerd 最低版本为 1.6

{% note warning %}
    升级集群时，需先将Containerd升级到1.6.0及以上版本后，才能将节点升级到Kubernetes 1.26。
{% endnote %}

## 1.2 PodSecurityPolicy

Kubernetes在1.21版本中弃用PodSecurityPolicy，在Kubernetes 1.25版本中彻底移除。

## 

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  ordinals:
    start: 10
  replicas: 5
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: "validate-xyz.example.com"
spec:
  singletonPolicy: true
  match:
    resourceRules:
    - apiGroups:   ["apps"]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["deployments"]
  defaultValidations:
  - expression: "object.spec.replicas < 100"
```


```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-prod-pvc
  namespace: prod
spec:
  from:
  - group: ""
    kind: PersistentVolumeClaim
    namespace: dev
  to:
  - group: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: new-snapshot-demo
```


```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc
  namespace: dev
spec:
  storageClassName: example
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  dataSourceRef:
    apiGroup: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: new-snapshot-demo
    namespace: prod
  volumeMode: Filesystem
```