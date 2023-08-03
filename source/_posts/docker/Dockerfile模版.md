---
layout: docker
title: Dockerfile模版
date: 2023-07-27 15:34:10
tags: docker
---

#### 1. 一个适用于我自己的模板

```dockerfile
FROM golang:1.20 as builder
WORKDIR /root/
COPY . .
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-mod=vendor go build -o app main.go

# =================================== 分层编译 ==============================================
FROM alpine AS final

# 国内使用的goproxy
ENV GOPROXY=https://goproxy.cn

# 设置时区
ENV TZ=Asia/Shanghai
RUN apk add --update tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/cache/apk/*

WORKDIR /root/
COPY --from=builder /root/app .
COPY ./mydir/  ./mydir/
RUN chmod +x app \
    && wget  https://storage.googleapis.com/kubernetes-release/release/v1.14.7/bin/linux/amd64/kubectl \
    && chmod +x kubectl
EXPOSE 8080
ENTRYPOINT ["/root/app"]
```

#### 2. COPY vs ADD

没有特殊需求情况下，建议使用COPY

###### 1. ADD 会自动解压压缩文件。
  

###### 2. ADD 支持源文件URL形式。

```dockerfile
ADD http://example.com/example.txt /app/
```

#### 3. CMD vs ENTRYPOINT

###### 1. docker run 如果指定了命令会覆盖

###### 2. 下面是等价的
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