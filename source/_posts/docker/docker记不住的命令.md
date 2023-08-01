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
docker run -d --net=host --name x-ui -v /etc/x-ui:/etc/x-ui/ xxx/xxx/x-ui:latest
```

#### 安装最新版 docker
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