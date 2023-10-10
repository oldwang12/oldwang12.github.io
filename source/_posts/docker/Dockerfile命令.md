---
layout: docker
title: Dockerfile 命令
date: 2023-07-27 15:34:10
tags: [docker,dockerfile]
categories: docker
---

{% note primary%}

一个适用于我自己的模板，附带一些命令讲解。

{% endnote %}

<!-- more -->
## 1. 模板

## 2. COPY vs ADD

没有特殊需求情况下，建议使用`COPY`

**ADD会自动解压压缩文件**
  

**ADD 支持源文件URL形式**

```dockerfile
ADD http://example.com/example.txt /app/
```

## 3. CMD vs ENTRYPOINT

**docker run 如果指定了命令会覆盖**

**下面是等价的**
```dockerfile
CMD ["python", "app.py"]
```

```dockerfile
ENTRYPOINT ["python", "app.py"]
```

```dockerfile
# 由 CMD 指令指定默认的可选参数：
ENTRYPOINT ["python"]
CMD ["app.py"]
```