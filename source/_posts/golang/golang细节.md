---
layout: golang
title: golang细节
date: 2023-07-29 13:20:35
tags: golang
---

### 目录
 
[1. 结构体打印时，%v 和 %+v 的区别](#1)
[2. new和make的区别](#2)
[3. slice扩容机制？](#3)

 
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