---
layout: 工具
title: xui客户端配置
date: 2023-07-28 15:46:40
tags: 工具
---

注意: 只适用于linux环境，下载 [v2ray-core](https://github.com/v2ray/v2ray-core/releases)，解压后替换 config.yaml 如下。执行 ./v2ray
```yaml
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "direct",
                "type": "field"
            }
        ]
    },
    "inbounds": [
        {
            "port": 1080,
            "protocol": "socks",
            "settings": {
                "auth": "noauth",
                "udp": true
            },
            "tag": "socks"
        }
    ],
    "outbounds": [
        {
            "protocol": "vmess",
            "settings": {
                "vnext": [
                    {
                        "users": [
                            {
                                "id": "<uuid>"
                            }
                        ],
                        "port": <服务端端口>,
                        "address": "<服务端IP>"
                    }
                ]
            }
        },
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
```