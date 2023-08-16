---
layout: linux
title: 快速开启http服务
date: 2023-08-07 17:22:35
tags: linux
categories: linux
---

#### 快速开启http服务

这将监听本地 80 端口，响应 OK
```sh
echo -e 'HTTP/1.1 200 OK\r\n\r\nOK' | sudo socat - TCP-LISTEN:80
```