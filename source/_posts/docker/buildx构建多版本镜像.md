---
layout: docker
title: buildx构建多版本镜像
date: 2023-08-03 15:23:18
tags: "docker"
categories: docker
---

{% note primary%}

目前大部分使用docker的场景中不单单只是 amd64 平台了有时我们需要再 arm 和 adm64 上都能运行

{% endnote %}

<!--more-->

[参考资料](http://blog.naturelr.cc/2023/06/16/%E4%BD%BF%E7%94%A8buildx%E7%BC%96%E8%AF%91%E5%A4%9A%E5%B9%B3%E5%8F%B0%E9%95%9C%E5%83%8F/)

新版本的docker默认自带 buildx

## 1. 创建buildx

### 1.1. 查看当前buildx实例

```sh
$ docker buildx ls
NAME/NODE DRIVER/ENDPOINT STATUS  BUILDKIT PLATFORMS
default * docker
  default default         running 23.0.5   linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
```

> 默认会有个实例叫default，default实例下有一个default的node，一个实例下可以有多个node,星号是默认使用的实例,node有很多种类型

### 1.2. 创建buildx

```shell
docker buildx create --name all --node local --driver docker-container --platform linux/amd64,linux/arm64,linux/arm/v8 --use
```

- 使用这个实例

```shell
docker buildx use all
```

- 当我们执行编译的时候会先下载buildx镜像并运行起来，然后使用这个容器运行的buildx来编译镜像

## 2. 编译

**--platform执行要编译的平台，其他的参数和普通的build差不多**

```sh
# 直接上传到仓库
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t bearking0425/m3u8-downloader -o type=registry .

# 输出本地
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t bearking0425/m3u8-downloader -o type=local,dest=./output .

# tar包
docker buildx build --platform linux/amd64,linux/arm64,linux/arm -t bearking0425/m3u8-downloader --output type=tar,dest=./output.tar .

# 直接导入到本地 docker 中，只支持单平台架构
docker buildx build --platform linux/arm64 -t bearking0425/m3u8-downloader --load . 
```