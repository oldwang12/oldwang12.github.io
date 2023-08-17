---
layout: golang
title: 如何分配IP
date: 2023-07-24 18:33:58
tags: golang
categories: golang
---


{% note primary%}

当我们有一段或者多段IP时，如何从IP池中分配出一个IP？

{% endnote %}

<!-- more -->

## 创建配置文件

```sh
cat <<EOF > ipam.json
{
  "ranges": [
    {
      "start": "10.172.16.2",
      "end": "10.172.16.3"
    },
    {
      "start": "10.172.17.2",
      "end": "10.172.17.3"
    }
  ]
}
EOF
```

## 代码实现

[ipam](https://github.com/oldwang12/ipam)
