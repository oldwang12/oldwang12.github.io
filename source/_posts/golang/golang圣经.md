---
layout: golang
title: golang 圣经
date: 2023-07-29 13:20:35
tags: golang
categories: golang
---

{% note primary %}

日积月累便封神。

{% endnote %}

<!-- more -->
 
# 1. time 包

{% note primary %}

时间格式、超时处理、定时器。

{% endnote %}

<!--more-->

## 1.1. 时间格式

```go
	timelocal, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		panic(err)
	}
	time.Local = timelocal
	fmt.Println(time.Now().Local().Format("2006-01-02 15:04:05"))
```

## 1.2. 超时处理

### 1.2.1. 使用select
  
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

###  1.2.2. 使用 time.Since
  
```go
	startTime := time.Now()
	timeout := 5 * time.Second

    time.Sleep(10 * time.Second)

    if time.Since(startTime) > timeout {
        return fmt.Errorf("timeout")
    }
```
##  1.3. 定时器

###  1.3.1. timer
  
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
###  1.3.2. ticker
  
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

# 2. gin 跨域问题
{% note warning %}

解决跨域问题

{% endnote %}

代码加入这一段就可以了

```go
r := gin.Default()
r.Use(Cors())

func Cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		method := c.Request.Method
		origin := c.Request.Header.Get("Origin")
		if origin != "" {
			c.Header("Access-Control-Allow-Origin", "*") // 可将将 * 替换为指定的域名
			c.Header("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE, UPDATE")
			c.Header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization")
			c.Header("Access-Control-Expose-Headers", "Content-Length, Access-Control-Allow-Origin, Access-Control-Allow-Headers, Cache-Control, Content-Language, Content-Type")
			c.Header("Access-Control-Allow-Credentials", "true")
		}
		if method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
		}
		c.Next()
	}
}
```

# 3. 分配 IP
{% note warning %}

当我们有一段或者多段IP时，如何从IP池中分配出一个IP？

{% endnote %}

**创建配置文件**

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

**代码实现**

[ipam](https://github.com/oldwang12/ipam)

# 4. 无法下载kubernetes包


{% note warning %}

解决无法直接下载 k8s.io/kubernetes 包问题

{% endnote %}

如果我们直接 go get k8s.io/kubernetes@v1.19.2 下载依赖，会出现以下错误:

```go
go get k8s.io/kubernetes@v1.19.2
go: downloading k8s.io/kubernetes v1.19.2
go: k8s.io/kubernetes@v1.19.2 requires
        k8s.io/api@v0.0.0: reading k8s.io/api/go.mod at revision v0.0.0:
```

错误的原因是在kubernetes主仓中，也使用了公共库，不过go.mod文件中所有公共库版本都指定为了v0.0.0（显然这个版本不存在）， 然后通过Go Module的replace机制，将版本替换为子目录./staging/src/k8s.io对应的依赖。

保存内容为 go-get-kubernetes.sh, 执行 ./go-get-kubernetes.sh v1.19.2，会自动在go.mod中替换。
```sh
#!/bin/sh
set -euo pipefail

VERSION=${1#"v"}
if [ -z "$VERSION" ]; then
    echo "Must specify version!"
    exit 1
fi
MODS=($(
    curl -sS https://raw.githubusercontent.com/kubernetes/kubernetes/v${VERSION}/go.mod |
    sed -n 's|.*k8s.io/\(.*\) => ./staging/src/k8s.io/.*|k8s.io/\1|p'
))
for MOD in "${MODS[@]}"; do

    V=$(
        go mod download -json "${MOD}@kubernetes-${VERSION}" |
        sed -n 's|.*"Version": "\(.*\)".*|\1|p'
    )
    go mod edit "-replace=${MOD}=${MOD}@${V}"
done
go get "k8s.io/kubernetes@v${VERSION}"
```

# 5. 结构体打印时，%v 和 %+v 的区别
```go
func printStruct(){
	people := People{
		Name: "lisi",
		Age:  18,
	}
	fmt.Printf("%v\n", people)
	fmt.Printf("%+v\n", people)
	fmt.Printf("%#v\n", people)
}
// 输出:
// {lisi 18}
// {Name:lisi Age:18}
// People{Name:"lisi", Age:18}
```

<p id="2"></p>
 
# 6. new 和 make的区别

* new只用于分配内存，返回一个指向地址的指针。它为每个新类型分配一片内存，初始化为0且返回类型*T的内存地址，它相当于&T{}
* make只可用于slice,map,channel的初始化,返回的是引用。

# 7. 什么是协程？

协程是用户态轻量级线程，它是线程调度的基本单位。通常在函数前加上go关键字就能实现并发。一个Goroutine会以一个很小的栈启动2KB或4KB，当遇到栈空间不足时，栈会自动伸缩， 因此可以轻易实现成千上万个goroutine同时启动。

# 8. defer执行顺序

后进先出

```go
func test() int {
	i := 0
	defer func() {
		fmt.Println("defer1")
	}()
	defer func() {
		i += 1
		fmt.Println("defer2")
	}()
	return i
}

func main() {
	fmt.Println("return", test())
}
// 输出:
// defer2
// defer1
// return 0
```

上面这个例子中，test返回值并没有修改，这是由于Go的返回机制决定的，执行Return语句后，Go会创建一个临时变量保存返回值。如果是有名返回（也就是指明返回值func test() (i int)）

```go
func test() (i int) {
	i = 0
	defer func() {
		i += 1
		fmt.Println("defer2")
	}()
	return i
}

func main() {
	fmt.Println("return", test())
}
// defer2
// return 1
```

这个例子中，返回值被修改了。对于有名返回值的函数，执行 return 语句时，并不会再创建临时变量保存，因此，defer 语句修改了 i，即对返回值产生了影响。


# 9. 如何判断 map 中是否包含某个 key ？
```go
var sample map[int]int
if _, ok := sample[10]; ok {
} else {
}
```

# 10. 如何获取一个结构体的所有tag？
```go
package main

import (
	"reflect"
	"fmt"
)

type Author struct {
	Name         int      `json:Name`
	Publications []string `json:Publication,omitempty`
}

func main() {
	t := reflect.TypeOf(Author{})
	for i := 0; i < t.NumField(); i++ {
		name := t.Field(i).Name
		s, _ := t.FieldByName(name)
		fmt.Println(name, s.Tag)
	}
}
// Name json:Name
// Publications json:Publication,omitempty
```

# 11. 如何判断 2 个字符串切片（slice) 是相等的？

```go
package main

import (
	"fmt"
	"reflect"
)

func main() {
	x := "abcd"
	y := "abcde"
	fmt.Println(reflect.DeepEqual(x, y))
	// Output: false
}
```

# 12. go里面的int和int32是同一个概念吗？
不是一个概念！千万不能混淆。go语言中的int的大小是和操作系统位数相关的，如果是32位操作系统，int类型的大小就是4字节。如果是64位操作系统，int类型的大小就是8个字节。除此之外uint也与操作系统有关。

int8占1个字节，int16占2个字节，int32占4个字节，int64占8个字节。


# 13. init() 函数

- init()函数是go初始化的一部分，由runtime初始化每个导入的包，初始化不是按照从上到下的导入顺序，而是按照解析的依赖关系，没有依赖的包最先初始化。
- 每个包首先初始化包作用域的常量和变量（常量优先于变量），然后执行包的init()函数。同一个包，甚至是同一个源文件可以有多个init()函数。
- init()函数没有入参和返回值，不能被其他函数调用，
- <span style="color: green;">同一个包内多个init()函数的执行顺序不作保证。</span>
- 一个文件可以有多个init()函数！
- 执行顺序：import –> const –> var –>init()–>main()

# 14. 2 个 nil 可能不相等吗？
可能不等。interface在运行时绑定值，只有值为nil接口值才为nil，但是与指针的nil不相等。举个例子：

```go
var p *int = nil
var i interface{} = nil
if(p == i){
	fmt.Println("Equal")
}
```
两者并不相同。总结：<span style="color: green;">两个nil只有在类型相同时才相等。</span>

# 15. copy vs 赋值

**1. 注意**
```go
	slice1 := []int{1, 2, 3, 4, 5}
	slice2 := []int{5, 4, 3}
	copy(slice2, slice1) // 只会复制slice1的前3个元素到slice2中
	copy(slice1, slice2) // 只会复制slice2的3个元素到slice1的前3个位置
```

**2. 区别**
```go
package  main

import "fmt"

func main() {
	test1()
	test2()
}

func test1() {
	a := []int{1,2,3,4,5}
	b := a  //等号赋值
	fmt.Printf("b切片的值%v，a地址%p,b地址%p\n", b, a, b)
	a[0] = 100
	fmt.Printf("等号赋值当改变源值，新值也会改变 %v\n", b)
}

func test2() {
	a := []int{1,2,3,4,5}
	b := make([]int, len(a))
	copy(b, a)
	fmt.Printf("b切片的值%v，a地址%p,b地址%p\n", b, a, b)
	a[0] = 100
	fmt.Printf("copy赋值当改变源值，新值不会改变 %v\n", b)
}
```

{% note warning %}

**输出：**
b切片的值`[1 2 3 4 5]`，a地址`0xc00008a030`, b地址 `0xc00008a030`
等号赋值当改变源值，新值也会改变 `[100 2 3 4 5]`
b切片的值`[1 2 3 4 5]`，a地址`0xc00008a060`,b地址`0xc00008a090`
copy赋值当改变源值，新值不会改变 `[1 2 3 4 5]`

{% endnote %}
