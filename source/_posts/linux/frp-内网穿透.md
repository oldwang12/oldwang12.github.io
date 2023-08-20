---
layout: frp 内网穿透
title: frp 内网穿透
category: linux
date: 2023-08-19 15:20:37
updated:
tags: [frp,nas]
---

{% note primary%}

公网服务器上安装 frp 服务端，内网服务器安装 frp 客户端。

{% endnote %}

<!-- more -->

## 1. 服务端

/etc/systemd/system/frps.service
```sh
[Unit]
# 服务名称，可自定义
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
# 启动frps的命令，需修改为您的frps的安装路径
ExecStart = /root/frp/frps -c /root/frp/frps.ini

[Install]
WantedBy = multi-user.target
```

/frp/.frp/frps.ini
```sh
[common]
bind_port = 7000
dashboard_port = 7500
token = abcdefg
dashboard_user = xx
dashboard_pwd = xx
vhost_http_port = 10080
vhost_https_port = 10443
```

## 2. 客户端


/etc/systemd/system/frpc.service

```sh
[Unit]
# 服务名称，可自定义
Description = frp client
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
# 启动frps的命令，需修改为您的frpc的安装路径
ExecStart = /root/frp/frpc -c /root/frp/frpc.ini

[Install]
WantedBy = multi-user.target
```

/root/frp/frpc.ini

```sh
[common]
server_addr = 100.100.100.100
server_port = 7000
token = abcdefg

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 6000

[alist]
type = tcp
local_ip = 127.0.0.1
local_port = 5244
remote_port = 55244
```