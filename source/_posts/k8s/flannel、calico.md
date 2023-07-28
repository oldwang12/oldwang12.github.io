---
layout: k8s
title: flannel、calico
date: 2023-07-27 14:31:00
tags: k8s
---

# flannel

3种封装和路由模式

* UDP
* VXLAN
* host-gateway

UDP、VXLAN模式基于三层网络，host-gateway需要在二层网络同一个交换机下才能实现。