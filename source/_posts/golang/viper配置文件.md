---
layout: golang
title: viper配置文件
date: 2023-07-29 13:08:23
tags: golang
categories: golang
---

#### 配置文件
```yaml
mysql:
  url: 127.0.0.1
  port: 3306
isvalid: true
```

#### 代码示例
```go
package main

import (
	"fmt"
	"github.com/spf13/viper"
)

func main() {
	// 设置配置文件的名字
	viper.SetConfigName("config")
	// 设置配置文件的类型
	viper.SetConfigType("yaml")
	// 添加配置文件的路径，指定 config 目录下寻找
	viper.AddConfigPath("./config")
	// 寻找配置文件并读取
	err := viper.ReadInConfig()
	if err != nil {
		panic(fmt.Errorf("fatal error config file: %w", err))
	}
	fmt.Println(viper.Get("mysql"))
	fmt.Println(viper.GetString("mysql.url"))
	fmt.Println(viper.GetInt("mysql.port"))
	fmt.Println(viper.GetBool("isvalid"))
}
```