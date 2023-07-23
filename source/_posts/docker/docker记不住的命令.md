---
layout: docker
title: docker记不住的命令
date: 2023-07-23 00:20:28
type: "tags"
tags: "docker"
---

#### 启动一个容器

```yaml
# -p: 8888为主机端口，3306为容器端口
# -e: 环境变量设置
# 最后的 mysql 为镜像 
docker run -itd --name mysql-test -p 8888:3306 -e MYSQL_ROOT_PASSWORD=123456 mysql
```

#### 删除所有未使用的镜像
```yaml
 docker system prune -a
 ```

#### mac 清理镜像层
```sh
rm ~/Library/Containers/com.docker.docker
```

#### 启动 x-ui
```sh
docker run -d --net=host --name x-ui -v /etc/x-ui:/etc/x-ui/ uhub.service.ucloud.cn/naturelr/x-ui:latest
```

#### 修改容器中的时区信息
```sh
FROM alpine

ENV TZ=Asia/Shanghai
RUN apk add --update tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/cache/apk/*
```