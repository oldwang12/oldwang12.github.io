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