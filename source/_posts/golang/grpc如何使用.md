---
layout: golang
title: grpc如何使用
date: 2023-07-31 17:04:16
tags: golang
categories: golang
---

{% note primary %}

grpc 最基本的使用。

{% endnote %}

<!-- more -->

#### 安装grpc
```sh
go get google.golang.org/grpc@latest
```

#### 安装Protocol Buffers v3

protoc [下载](https://github.com/google/protobuf/releases)

#### 安装插件
```sh
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2
```

# 入门示例

[代码实现](https://github.com/oldwang12/grpc-demo)

## 服务端

#### 编写proto代码
```sh
cat <<EOF > pb/hello.proto
syntax = "proto3"; // 版本声明，使用Protocol Buffers v3版本

option go_package = "server/pb";  // 指定生成的Go代码在你项目中的导入路径

package pb; // 包名


// 定义服务
service Greeter {
    // SayHello 方法
    rpc SayHello (HelloRequest) returns (HelloResponse) {}
}

// 请求消息
message HelloRequest {
    string name = 1;
}

// 响应消息
message HelloResponse {
    string reply = 1;
}
EOF
```

* 执行命令：
```sh
protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative pb/hello.proto
```

#### 编写Server端Go代码

```go
package main

import (
	"context"
	"fmt"
	"hello_server/pb"
	"net"

	"google.golang.org/grpc"
)

// hello server

type server struct {
	pb.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloResponse, error) {
	return &pb.HelloResponse{Reply: "Hello " + in.Name}, nil
}

func main() {
	// 监听本地的8972端口
	lis, err := net.Listen("tcp", ":8972")
	if err != nil {
		fmt.Printf("failed to listen: %v", err)
		return
	}
	s := grpc.NewServer()                  // 创建gRPC服务器
	pb.RegisterGreeterServer(s, &server{}) // 在gRPC服务端注册服务
	// 启动服务
	err = s.Serve(lis)
	if err != nil {
		fmt.Printf("failed to serve: %v", err)
		return
	}
}
```

#### 代码结构

```
server
├── go.mod
├── go.sum
├── main.go
└── pb
    ├── hello.pb.go
    ├── hello.proto
    └── hello_grpc.pb.go
```

#### 运行
```sh
go run main.go
```

## 客户端

#### 编写proto代码

新建 client 项目

将 go_package 改为 "client/db"

```sh
cat <<EOF > pb/hello.proto
syntax = "proto3"; // 版本声明，使用Protocol Buffers v3版本

option go_package = "client/pb";  // 指定生成的Go代码在你项目中的导入路径

package pb; // 包名


// 定义服务
service Greeter {
    // SayHello 方法
    rpc SayHello (HelloRequest) returns (HelloResponse) {}
}

// 请求消息
message HelloRequest {
    string name = 1;
}

// 响应消息
message HelloResponse {
    string reply = 1;
}
EOF
```

* 执行命令
```sh
protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative pb/hello.proto
```

#### client 端代码
```go
package main

import (
	"context"
	"flag"
	"log"
	"time"

	"hello_client/pb"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// hello_client

const (
	defaultName = "world"
)

var (
	addr = flag.String("addr", "127.0.0.1:8972", "the address to connect to")
	name = flag.String("name", defaultName, "Name to greet")
)

func main() {
	flag.Parse()
	// 连接到server端，此处禁用安全传输
	conn, err := grpc.Dial(*addr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	// 执行RPC调用并打印收到的响应数据
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: *name})
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.GetReply())
}
```

#### 代码结构
```
http_client
├── go.mod
├── go.sum
├── main.go
└── pb
    ├── hello.pb.go
    ├── hello.proto
    └── hello_grpc.pb.go
```

## 结果
```sh
$ go run main.go -name=李四
Greeting: Hello 李四
```