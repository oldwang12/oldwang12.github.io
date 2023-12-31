---
layout: docker
title: docker记不住的命令
date: 2023-07-23 00:20:28
type: "tags"
tags: "docker"
categories: docker
---

{% note primary%}

不想记，也记不住

{% endnote %}

<!--more-->

## 1. 启动一个容器

```yaml
# -p: 8888为主机端口，3306为容器端口
# -e: 环境变量设置
# 最后的 mysql 为镜像 
docker run -itd --name mysql-test -p 8888:3306 -e MYSQL_ROOT_PASSWORD=123456 mysql
```
## 2. 列出所有的容器 ID
```sh
docker ps -aq
```

## 3. 停止所有的容器
```sh
docker stop $(docker ps -aq)
```

## 4. 删除所有的容器
```sh
docker rm $(docker ps -aq)
```

## 5. 删除所有的镜像
```sh
docker rmi $(docker images -q)
```
## 6. 删除所有未使用的镜像
```sh
docker system prune -a
```
## 7. 删除 none 相关镜像

**docker**
```sh
docker rmi $(docker images | grep none | awk '{print $3}')
```

**containerd**
```sh
crictl rmi $(crictl images | grep none | awk '{print $3}')
```

## 8. 拉取指定版本镜像
```sh
docker pull tickstep/aliyunpan-sync:v0.2.7 --platform=linux/arm/v7
```

## 9. 看下具体的每层镜像大小

```sh
docker history --no-trunc 【镜像名】
```

## 10. mac 清理镜像层
```sh
rm ~/Library/Containers/com.docker.docker
```
## 11. 复制文件

```sh
docker cp mycontainer:/opt/file.txt /opt/local/
docker cp /opt/local/file.txt mycontainer:/opt/
```
## 12. 启动 x-ui
```sh
docker run -d --net=host --name x-ui -v /etc/x-ui:/etc/x-ui/ xxx/xxx/x-ui:latest
```

## 13. 安装最新版 docker
```sh
yum update -y
```
你可以单独执行更新。

```sh
# 删除旧版本的Docker
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
# 安装依赖软件包
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# 添加Docker软件源
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 更新yum缓存
sudo yum makecache fast
# 安装最新版Docker
sudo yum install -y docker-ce
# 启动Docker服务并设置开机自启动
sudo systemctl start docker
sudo systemctl enable docker
# 确认Docker已安装并正在运行
docker --version
sudo docker info
```

## 14. 查看容器资源占用
```sh
# 持续监控
docker stats

# 输出当前
docker stats --no-stream
```

