---
layout: golang
title: golang面试
date: 2023-07-29 13:20:35
tags: golang
categories: golang
---

### 目录
 
[1. 结构体打印时，%v 和 %+v 的区别](#1)
[2. new和make的区别](#2)
[3. slice扩容机制？](#3)
[4. 什么是协程？](#4)
[5. defer执行顺序](#5)
[6. 如何判断 map 中是否包含某个 key ?](#6)
[7. 如何获取一个结构体的所有tag？](#7)
[8. 如何判断 2 个字符串切片（slice) 是相等的？](#8)
[9. go里面的int和int32是同一个概念吗？](#9)
[10. init() 函数](#10)
[11. 2 个 nil 可能不相等吗？](#11)

 
<p id="1"></p>
 
#### 结构体打印时，%v 和 %+v 的区别
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
 
#### new 和 make的区别

* new只用于分配内存，返回一个指向地址的指针。它为每个新类型分配一片内存，初始化为0且返回类型*T的内存地址，它相当于&T{}
* make只可用于slice,map,channel的初始化,返回的是引用。

<p id="3"></p>

#### slice扩容机制？
Go <= 1.17

如果当前容量小于1024，则判断所需容量是否大于原来容量2倍，如果大于，当前容量加上所需容量；否则当前容量乘2。

如果当前容量大于1024，则每次按照1.25倍速度递增容量，也就是每次加上cap/4。

Go1.18之后，引入了新的扩容规则：浅谈 Go 1.18.1的切片扩容机制

<p id="4"></p>

#### 什么是协程？

协程是用户态轻量级线程，它是线程调度的基本单位。通常在函数前加上go关键字就能实现并发。一个Goroutine会以一个很小的栈启动2KB或4KB，当遇到栈空间不足时，栈会自动伸缩， 因此可以轻易实现成千上万个goroutine同时启动。

<p id="5"></p>

#### defer执行顺序

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


<p id="6"></p>

#### 如何判断 map 中是否包含某个 key ？
```go
var sample map[int]int
if _, ok := sample[10]; ok {
} else {
}
```

<p id="7"></p>

#### 如何获取一个结构体的所有tag？
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

<p id="8"></p>

#### 如何判断 2 个字符串切片（slice) 是相等的？

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

<p id="9"></p>

#### go里面的int和int32是同一个概念吗？
不是一个概念！千万不能混淆。go语言中的int的大小是和操作系统位数相关的，如果是32位操作系统，int类型的大小就是4字节。如果是64位操作系统，int类型的大小就是8个字节。除此之外uint也与操作系统有关。

int8占1个字节，int16占2个字节，int32占4个字节，int64占8个字节。


<p id="10"></p>

#### init() 函数

- init()函数是go初始化的一部分，由runtime初始化每个导入的包，初始化不是按照从上到下的导入顺序，而是按照解析的依赖关系，没有依赖的包最先初始化。
- 每个包首先初始化包作用域的常量和变量（常量优先于变量），然后执行包的init()函数。同一个包，甚至是同一个源文件可以有多个init()函数。
- init()函数没有入参和返回值，不能被其他函数调用，
- <span style="color: green;">同一个包内多个init()函数的执行顺序不作保证。</span>
- 一个文件可以有多个init()函数！
- 执行顺序：import –> const –> var –>init()–>main()

<p id="11"></p>

#### 2 个 nil 可能不相等吗？
可能不等。interface在运行时绑定值，只有值为nil接口值才为nil，但是与指针的nil不相等。举个例子：

```go
var p *int = nil
var i interface{} = nil
if(p == i){
	fmt.Println("Equal")
}
```
两者并不相同。总结：<span style="color: green;">两个nil只有在类型相同时才相等。</span>

