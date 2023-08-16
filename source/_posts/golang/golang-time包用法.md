---
layout: golang
title: golang time包用法
date: 2023-07-27 15:33:31
tags: golang
categories: golang
---

#### 时间格式
```go
	timelocal, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		panic(err)
	}
	time.Local = timelocal
	fmt.Println(time.Now().Local().Format("2006-01-02 15:04:05"))
```

#### 超时处理

* 1. 使用select
```go
    c1 := make(chan string, 1)
    go func() {
        time.Sleep(time.Second * 2)
        c1 <- "result 1"
    }()

    select {
    case res := <-c1:
        fmt.Println(res)
    case <-time.After(time.Second * 1):
        fmt.Println("timeout 1")
    }
```

* 2. 使用 time.Since
```go
	startTime := time.Now()
	timeout := 5 * time.Second

    time.Sleep(10 * time.Second)

    if time.Since(startTime) > timeout {
        return fmt.Errorf("timeout")
    }
```
#### 定时器

* 1. timer
```go
func main() {
	// NewTimer 创建一个 Timer，它会在最少过去时间段 d 后到期，向其自身的 C 字段发送当时的时间
	timer1 := time.NewTimer(5 * time.Second)

	fmt.Println("开始时间：", time.Now().Format("2006-01-02 15:04:05"))
	go func(t *time.Timer) {
		times := 0
		for {
			<-t.C
			fmt.Println("timer", time.Now().Format("2006-01-02 15:04:05"))

			times++
			fmt.Println("调用 reset 重新设置一次timer定时器，并将时间修改为2秒")
			t.Reset(2 * time.Second)
			if times > 3 {
				fmt.Println("调用 stop 停止定时器")
				t.Stop()
			}
		}
	}(timer1)

	time.Sleep(30 * time.Second)
	fmt.Println("结束时间：", time.Now().Format("2006-01-02 15:04:05"))
}
```
* 2. ticker
  
```go
func main() {
	ticker1 := time.NewTicker(5 * time.Second)
	defer ticker1.Stop() // 一定要调用Stop()，回收资源
	go func(t *time.Ticker) {
		for {
			// 每5秒中从chan t.C 中读取一次
			<-t.C
			fmt.Println("Ticker:", time.Now().Format("2006-01-02 15:04:05"))
		}
	}(ticker1)

	time.Sleep(30 * time.Second)
	fmt.Println("ok")
}
```