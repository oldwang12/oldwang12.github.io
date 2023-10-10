---
title: 实现 DNS 双栈的一些细节
categories: 技术
date: 2023-09-05 11:20:13
updated:
tags: ["dns"]
layout: dns
---

# 1. 概述

当客户端是双栈环境时，客户端在向 DNS 服务器请求地址解析时，会同时发起域名 A 记录和 AAAA 记录的解析请求，如果后台支持双栈（或者DNS自己返回了双栈的解析结果），就会拿到对应的两种解析地址结果：IPv4 和 IPv6，拿到解析结果后，由客户端选择地址发起连接。
为了推广 IPv6，客户端应该从解析结果中优先选择 IPv6 进行连接，但由于当前 IPv6 基础建设尚未完善，连通性问题和可靠性问题不能得到有效保证，链接超时或失败会造成用户可感知的负面体验，有这些负面体验用户可能就完全禁止 IPv6，所以还是需要使用 IPv4 协议适当的做降级和兜底。
针对 IPv6 的回退和降级策略，IETF 于2012年发布 [RFC6555](https://datatracker.ietf.org/doc/html/rfc6555) 和2017年发布 [RFC8305](https://datatracker.ietf.org/doc/html/rfc8305) 两版 RFC 算法来描述了关于在域名解析、地址排序和连接尝试阶段v4配合v6升级适配的详细方案，该方案称为：Happy Eyeballs。

* RFC6555: Happy Eyeballs: Success with Dual-Stack Hosts
* RFC8305: Happy Eyeballs Version 2: Better Connectivity Using Concurrency

## Why Happy Eyeballs ?
```
The name "happy eyeballs" derives from the term "eyeball" to describe endpoints which represent human Internet end-users, as opposed to servers.
```
我的理解是，Happy Eyeballs 的关注点是人类本身而不是机器，人类在互联网上浏览网页，观看视频，不能因为 IPv6 和 IPv4 网络的连通性问题让他们眼球停留在加载页面，而应该让他们的眼球快乐起来。

RFC6555 描述了 Happy Eyeballs 原始算法，RFC8305 在 RFC6555 的基础上，添加了如下内容：

* 如何执行DNS查询以获取这些地址
* 如何处理每个地址族的多个地址
* 连接竞速时如何处理DNS更新
* 如何利用历史信息
* 如何适配使用NAT64和DNS64实现的单栈IPv6网络

RFC8305 描述的算法仍然符合 RFC6555 的规范，只不过更加细节化，RFC8305 的中文版参考这里。

# 2. Happy Eyeballs-快乐眼球算法

RFC8305 定义的 Happy Eyeballs 归纳如下：

1. 向DNS 服务器同时发起AAAA记录和A记录解析（AAAA 先于 A）
2. 如果v6地址先返回就直接开始握手建立连接，如果v4地址先返回，则等待 50ms 等待v6地址返回，以确保优先选择IPv6（AAAA响应跟随A响应几毫秒是很常见的）
3. 将所有已解析的目标地址排序，排序依据 ([RFC8305], Section 4) 及 ([RFC6724], Section 6)
4. 排序完成后，会依次有序的取地址发送握手请求，并启动定时任务，该任务在250ms后检查若未完成连接建立，则对第二个地址开始连接尝试
5. 只有有一个握手确认成功（建立了连接），就会取消所有其他的连接尝试



RFC6555 中有一点不一样的是，对解析的所有目标地址选取的算法参考的是 [RFC3484] ，[RFC3484]  已经被 [RFC6724] 取代，目的地址排序规则会影响 IPv4 及 IPv6 地址的先后顺序，具体我们在下一节分析。

Happy Eyeballs 要求在尝试连接之前，实现上不应该等待两个地址族都返回 answers，如果一个查询无法返回或者需要花费更长的时间返回，那么就会造成连接建立的延迟，因此，客户端应将 DNS 解析实现为异步。这一点在 curl 及 go 的实现中都没能做到，curl 会调用 getaddrinfo 方法获取所有地址解析结果后再尝试连接竞速，go 有自己实现的主机名到地址的解析函数，会根据系统及配置选择使用go原生的地址解析函数或者 getaddrinfo，但无论怎样，也是在获取所有地址解析结果后再尝试连接竞速。

总体来看，Happy Eyeballs 分为目的地址排序和连接竞速两个主要阶段，我们一一来看。

## 2.1. 目的地址排序

目的地址选取依据 [RFC3484] 及 [RFC6724]，[RFC3484] 已经被 [RFC6724] 取代，但是 getaddrinfo 还是使用了 [RFC3484] 进行目的地址选取排序，go 实现的主机名到地址的解析函数使用了 [RFC6724]。
注：[RFC3484] 和 [RFC6724] 描述了源地址及目的地址选取算法，这里我们只关注目的地址选取。

目的地址选取遵循 10 条规则，优先级 1 > 2 >3 > 4 ...，满足一条就返回。
目的地址中设计到一些名词我们重点关注一下：

* scope
* precedence
* label
* home addresses
* care-of address

 | 规则                  | RFC3484                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | RFC6724                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
 | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
 | Rule 1                | Rule 1: Avoid unusable destinations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Rule 1: Avoid unusable destinations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
 | 避免无法使用的地址    | If DB is known to be unreachable or if Source(DB) is undefined, then prefer DA. Similarly, if DA is known to be unreachable or if Source(DA) is undefined, then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | If DB is known to be unreachable or if Source(DB) is undefined, then prefer DA. Similarly, if DA is known to be unreachable or if Source(DA) is undefined, then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
 | Rule 2                | Rule 2: Prefer matching scope.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Rule 2: Prefer matching scope.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
 | 匹配源地址 scope 优先 | If Scope(DA) = Scope(Source(DA)) and Scope(DB) <> Scope(Source(DB)), then prefer DA.  Similarly, if Scope(DA) <> Scope(Source(DA)) and Scope(DB) = Scope(Source(DB)), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | If Scope(DA) = Scope(Source(DA)) and Scope(DB) <> Scope(Source(DB)), then prefer DA.  Similarly, if Scope(DA) <> Scope(Source(DA)) and Scope(DB) = Scope(Source(DB)), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
 | Rule 3                | Rule 3: Avoid deprecated addresses.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Rule 3: Avoid deprecated addresses.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
 | 避免已经弃用的地址    | If Source(DA) is deprecated and Source(DB) is not, then prefer DB. Similarly, if Source(DA) is not deprecated and Source(DB) is deprecated, then prefer DA.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | If Source(DA) is deprecated and Source(DB) is not, then prefer DB. Similarly, if Source(DA) is not deprecated and Source(DB) is deprecated, then prefer DA.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
 | Rule 4                | Rule 4: Prefer home addresses.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Rule 4: Prefer home addresses.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
 | home addresses 优先   | If Source(DA) is simultaneously a home address and care-of address and Source(DB) is not, then prefer DA.  Similarly, if Source(DB) is simultaneously a home address and care-of address and Source(DA) is not, then prefer DB. If Source(DA) is just a home address and Source(DB) is just a care-of address, then prefer DA.  Similarly, if Source(DA) is just a care-of address and Source(DB) is just a home address, then prefer DB.                                                                                                                                                                                                                                                                  | If Source(DA) is simultaneously a home address and care-of address and Source(DB) is not, then prefer DA.  Similarly, if Source(DB) is simultaneously a home address and care-of address and Source(DA) is not, then prefer DB. If Source(DA) is just a home address and Source(DB) is just a care-of address, then prefer DA.  Similarly, if Source(DA) is just a care-of address and Source(DB) is just a home address, then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                            |  |
 | Rule 5                | Rule 5: Prefer matching label.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Rule 5: Prefer matching label. If Label(Source(DA)) = Label(DA) and Label(Source(DB)) <> Label(DB), then prefer DA.  Similarly, if Label(Source(DA)) <> Label(DA) and Label(Source(DB)) = Label(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
 | 匹配 label 优先       | If Label(Source(DA)) = Label(DA) and Label(Source(DB)) <> Label(DB), then prefer DA.  Similarly, if Label(Source(DA)) <> Label(DA) and Label(Source(DB)) = Label(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
 | Rule 6                | Rule 6: Prefer higher precedence.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Rule 6: Prefer higher precedence.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
 | 高优先级优先          | If Precedence(DA) > Precedence(DB), then prefer DA.  Similarly, if Precedence(DA) < Precedence(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | If Precedence(DA) > Precedence(DB), then prefer DA.  Similarly, if Precedence(DA) < Precedence(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
 | Rule 7                | Rule 7: Prefer native transport.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Rule 7: Prefer native transport.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
 | 原生传输协议优先      | If DA is reached via an encapsulating transition mechanism (e.g., IPv6 in IPv4) and DB is not, then prefer DB.  Similarly, if DB is reached via encapsulation and DA is not, then prefer DA. Discussion:  6-over-4 [15], ISATAP [16], and configured tunnels [17] are examples of encapsulating transition mechanisms for which the destination address does not have a specific prefix and hence can not be assigned a lower precedence in the policy table.  An implementation MAY generalize this rule by using a concept of interface preference, and giving virtual interfaces (like the IPv6-in-IPv4 encapsulating interfaces) a lower preference than native interfaces (like ethernet interfaces). | If DA is reached via an encapsulating transition mechanism (e.g., IPv6 in IPv4) and DB is not, then prefer DB.  Similarly, if DB is reached via encapsulation and DA is not, then prefer DA. Discussion: The IPv6 Rapid Deployment on IPv4 Infrastructures (6rd) Protocol [RFC5969], the Intra-Site Automatic Tunnel Addressing Protocol (ISATAP) [RFC5214], and configured tunnels [RFC4213] are examples of encapsulating transition mechanisms for which the destination address does not have a specific prefix and hence can not be assigned a lower precedence in the policy table. An implementation MAY generalize this rule by using a concept of interface preference and giving virtual interfaces (like the IPv6-in-IPv4 encapsulating interfaces) a lower preference than native interfaces (like ethernet interfaces). |
 | Rule 8                | Rule 8: Prefer smaller scope.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Rule 8: Prefer smaller scope.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
 | 更小的 scope 优先     | If Scope(DA) < Scope(DB), then prefer DA.  Similarly, if Scope(DA) > Scope(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | If Scope(DA) < Scope(DB), then prefer DA.  Similarly, if Scope(DA) > Scope(DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
 | Rule 9                | Rule 9: Use longest matching prefix.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Rule 9: Use longest matching prefix.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
 | 前缀匹配长度优先      | When DA and DB belong to the same address family (both are IPv6 or both are IPv4): If CommonPrefixLen(DA, Source(DA)) > CommonPrefixLen(DB, Source(DB)), then prefer DA.  Similarly, if CommonPrefixLen(DA, Source(DA)) < CommonPrefixLen(DB, Source(DB)), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                 | When DA and DB belong to the same address family (both are IPv6 or both are IPv4): If CommonPrefixLen(Source(DA), DA) > CommonPrefixLen(Source(DB), DB), then prefer DA.  Similarly, if CommonPrefixLen(Source(DA), DA) < CommonPrefixLen(Source(DB), DB), then prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
 | Rule 10               | Rule 10: Otherwise, leave the order unchanged.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Rule 10: Otherwise, leave the order unchanged.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
 | 默认规则              | If DA preceded DB in the original list, prefer DA.  Otherwise prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | If DA preceded DB in the original list, prefer DA.  Otherwise, prefer DB.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |


其中 label 和 precedence 在 默认策略表中定义，10 条规则基本没变，只是对默认策略表进行了一些更改：

[RFC3484] 默认策略表
```
      Prefix        Precedence Label
      ::1/128               50     0
      ::/0                  40     1
      2002::/16             30     2
      ::/96                 20     3
      ::ffff:0:0/96         10     4
```

[RFC6724]  默认策略表
```
      Prefix        Precedence Label
      ::1/128               50     0
      ::/0                  40     1
      ::ffff:0:0/96         35     4
      2002::/16             30     2 6to4 地址
      2001::/32              5     5 Teredo 地址
      fc00::/7               3    13
      ::/96                  1     3
      fec0::/10              1    11
      3ffe::/16              1    12
```
1. 添加 Teredo [RFC4380] 地址前缀 (2001::/32)，preference 和 label 值取自已经广泛使用的实现
2. 在原生 IPv6 地址前缀下添加 ULAs (fc00::/7) 地址，因为它不是全球可达地址，参见 Section 10.6
3. 取消推荐 site-local addresses (fec0::/10) ，因其已经被弃用 [RFC3879]
4. 调整原生 IPv4 地址优先 6to4 (2002::/32) 地址
5. 取消推荐 IPv4-Compatible addresses (::/96) 地址，因其被废弃且不再使用 [RFC4291]
6. 取消推荐  6bone testing addresses (3ffe::/16) 地址，因其已经被淘汰而不再首选 [RFC3701]
7. Added optional ability for an implementation to add automatic rows to the table for site-specific ULA prefixes and site-specific native 6to4 prefixes

根据上述规则对 dns 服务器返回的地址进行初步排序，再依据 ([RFC8305], Section 4) 进行 IPv4 和 IPv6 地址交错排序，形成最终的地址排序列表：如果返回的地址包含多个 IPv6 和 IPv4 地址，([RFC8305], Section 4) 中提到了两种实现：

* 第一种：v6 v6 v6 v4 v4 v4，地址族分段
* 第二种：v6 v4 v6 v4 v6 v4，地址族交错

地址排序之后，进行连接竞速。

### 2.1.1. 自定义默认策略表

策略表可以自己定义，用来控制不同地址的排序，比如 getaddrinfo 会读取 /etc/gai.conf 中的策略配置，如果没有特殊配置，getaddrinfo 使用默认的配置，默认将 6to4 地址排在原生 IPv4 地址前，我们可以：
将 precedence ::ffff:0:0/96  10
改 precedence ::ffff:0:0/96  35，使原生的 IPv4 地址优于 6to4 地址。

```
# Configuration for getaddrinfo(3).
#
# So far only configuration for the destination address sorting is needed.
# RFC 3484 governs the sorting.  But the RFC also says that system
# administrators should be able to overwrite the defaults.  This can be
# achieved here.
#
# All lines have an initial identifier specifying the option followed by
# up to two values.  Information specified in this file replaces the
# default information.  Complete absence of data of one kind causes the
# appropriate default information to be used.  The supported commands include:
#
# reload  <yes|no>
#    If set to yes, each getaddrinfo(3) call will check whether this file
#    changed and if necessary reload.  This option should not really be
#    used.  There are possible runtime problems.  The default is no.
#
# label   <mask>   <value>
#    Add another rule to the RFC 3484 label table.  See section 2.1 in
#    RFC 3484.  The default is:
#
label ::1/128       0
label ::/0          1
label 2002::/16     2
label ::/96         3
label ::ffff:0:0/96 4
label fec0::/10     5
label fc00::/7      6
label 2001:0::/32   7
label ::ffff:7f00:0001/128 8

#    This default differs from the tables given in RFC 3484 by handling
#    (now obsolete) site-local IPv6 addresses and Unique Local Addresses.
#    The reason for this difference is that these addresses are never
#    NATed while IPv4 site-local addresses most probably are.  Given
#    the precedence of IPv6 over IPv4 (see below) on machines having only
#    site-local IPv4 and IPv6 addresses a lookup for a global address would
#    see the IPv6 be preferred.  The result is a long delay because the
#    site-local IPv6 addresses cannot be used while the IPv4 address is
#    (at least for the foreseeable future) NATed.  We also treat Teredo
#    tunnels special.
#
# precedence  <mask>   <value>
#    Add another rule to the RFC 3484 precedence table.  See section 2.1
#    and 10.3 in RFC 3484.  The default is:
#
precedence  ::1/128       50
precedence  ::/0          40
precedence  2002::/16     30
precedence ::/96          20
precedence ::ffff:0:0/96  35

#
#    For sites which prefer IPv4 connections change the last line to
#
#precedence ::ffff:0:0/96  100

#
# scopev4  <mask>  <value>
#    Add another rule to the RFC 3484 scope table for IPv4 addresses.
#    By default the scope IDs described in section 3.2 in RFC 3484 are
#    used.  Changing these defaults should hardly ever be necessary.
#    The defaults are equivalent to:
#
scopev4 ::ffff:169.254.0.0/112  2
scopev4 ::ffff:127.0.0.0/104    2
scopev4 ::ffff:0.0.0.0/96       14
#
#    For sites which use site-local IPv4 addresses behind NAT there is
#    the problem that even if IPv4 addresses are preferred they do not
#    have the same scope and are therefore not sorted first.  To change
#    this use only these rules:
#
scopev4 ::ffff:169.254.0.0/112  2
scopev4 ::ffff:127.0.0.0/104    2
scopev4 ::ffff:0.0.0.0/96       14
```

## 2.2. 连接竞速

● 为避免无意义的网络连接，连接竞速过程不应该并行，而是依次有序的单个启动
● 在一定的连接尝试延时（推荐250ms）过后，再使用列表中的后续ip地址开始逐个尝试连接。
● 一旦首个 IP 连接握手成功后，即取消其他未完成的连接尝试。另外，DNS 客户端解析器仍应在短时间内（建议为1秒）处理来自网络的DNS回复，因为它们将填充 DNS 缓存，并可用于后续连接。
● 连接尝试延迟推荐为250ms，可根据相同域名的历史RTT数据采集来动态调整延时，但区间应限制在100ms-2s

# 3. 客户端实现

依据 Happy Eyeballs 算法，各语言的类库都有各自的实现，并且不会完全遵守 Happy Eyeballs。

## 3.1. Go 的实现

Go 实现了自己的主机名到地址的解析函数 goLookupIPCNAMEOrder，依据操作系统版本及相关配置会选择使用 goLookupIPCNAMEOrder  或是 libc 的 getaddrinfo 。默认在 Linux 系统中如果没有特殊配置 /etc/nsswitch.conf 和 /etc/resolv.conf 的话，Go 会使用 goLookupIPCNAMEOrder 发起域名解析请求(当 /etc/resolv.conf 文件中配置了 single-request，Go 会使用 getaddrinfo)。 goLookupIPCNAMEOrder 使用 [RFC6724] 对返回的地址进行排序。

假设 www.example.com 有下列
* 2002:a40:4c07:1::faf1 （6to4）
* 2002:a40:4c07:1::faf2（6to4）
* 2002:a40:4c07:1::faf3（6to4）
* 10.64.78.34
* 10.64.78.35
五个解析结果。

* 当 Go 使用 goLookupIPCNAMEOrder：


* 如果 Go 使用 getaddrinfo：

go 在调用 goLookupIPCNAMEOrder 或者 getaddrinfo 函数之后拿到排序过的地址解析列表，然后依据这个排序结果，如果在双栈环境下，地址列表第一个地址是 IPv4 地址，那么所有的 IPv4 放到 primaries 队列中，所有的 IPv6 地址放到 fallbacks 队列中（如果地址列表第一个地址是 IPv6 地址，所有的 IPv6 放到 primaries 队列中，所有的 IPv4 地址放到 fallbacks 队列中），接着优先顺序的对 primaries 队列中的地址尝试连接，如果 300ms（可配置）后连接未建立，那么顺序的对 fallbacks 队列中的地址发起连接（如果primaries队列地址连接出错会马上对 fallbacks 队列地址发起连接，不会等 300ms），任何一个连接成功后，其余连接将被关闭。

# 4. 客户端测试

**dns 服务器针对特殊域名，返回如下几种结果：**
1. 返回1个 IPv4 地址
2. 返回1个 IPv6 地址
3. 返回1个 IPv4 地址和1个 IPv6 地址
4. 返回1个 IPv4 地址和1个 broken IPv6 地址
5. 返回1个 broken IPv4 地址和1个 IPv6 地址
6. 返回1个 IPv4 地址和2个 IPv6 地址，其中一个 IPv6 地址 broken
7. 返回2个 IPv4 地址和1个 IPv6 地址，其中一个 IPv4 地址 broken

{% note warning %}

上面的 IPv6 地址指的是 6to4 地址，broken 指的是网络包丢失的场景，这里我们使用 iptables DROP 掉特殊的地址来模拟 broken。

{% endnote %}

**测试环境：**
* 内核版本：Linux 4.1.0-15.el6.ucloud.x86_64
* 操作系统：CentOS release 6.3 (Final)
* glibc 版本：2.12
* curl 版本：curl 7.72.0 (x86_64-redhat-linux-gnu)
* go 版本：go1.15 linux/amd64
* python 版本：Python 2.6.6
* nodejs 版本：v0.10.36
* java 版本："11.0.8" 2020-07-14 LTS
* nginx 版本：nginx/1.14.2

**使用 coredns file 插件进行测试，针对上面七种场景，配置7个文件：**
* 返回1个 IPv4 地址

```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN A     10.64.78.34
```
* 返回1个 IPv6 地址
  
```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::faf1
```

* 返回1个 IPv4 地址和1个 IPv6 地址
  
```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::faf1
        IN A     10.64.78.34
```

* 返回1个 IPv4 地址和1个 broken IPv6 地址
  
```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::faf2
        IN A     10.64.78.34
```

* 返回1个 broken IPv4 地址和1个 IPv6 地址
  
```
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::faf1
        IN A     10.64.78.35
```

* 返回1个 IPv4 地址和2个 IPv6 地址，其中一个 IPv6 地址 broken

```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::aaa1
        IN AAAA  2002:a40:4c07:1::faf1
        IN A     10.64.78.34
```

* 返回2个 IPv4 地址和1个 IPv6 地址，其中一个 IPv4 地址 broken

```
$ORIGIN example.org.
@	3600 IN	SOA sns.dns.icann.org. noc.dns.icann.org. (
				2017042745 ; serial
				7200       ; refresh (2 hours)
				3600       ; retry (1 hour)
				1209600    ; expire (2 weeks)
				3600       ; minimum (1 hour)
				)

	3600 IN NS a.iana-servers.net.
	3600 IN NS b.iana-servers.net.

WWW     IN AAAA  2002:a40:4c07:1::faf1
        IN A     10.64.78.33
        IN A     10.64.78.34
```

## 4.1. IPv4 only

执行命令禁用 IPv6:

```sh
sysctl net.ipv6.conf.all.disable_ipv6=1
sysctl net.ipv6.conf.default.disable_ipv6=1
```

| go                                                                                                                                                                                                                                                         | curl                                                                                                                                                                                                                                                       | python                                                                                                                                                                                                                                                                      | node.js                                                                                                                             | java                                                                                                                      | nginx                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                                            | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                                            | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                              |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端无法完成连接                                                                                                                                                                      | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端无法完成连接                                                                                                                                                                      | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端无法完成连接                                                                                                                                                                                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端无法完成连接                                               | 客户端只发起 A 记录解析请求，DNS服务 返回 NOERROR，客户端无法完成连接                                                     | 客户端只发起 A 记录解析请求，DNS服务 返回 NOERROR，nginx 无法启动                                                                                                                                                                  |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                              | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                              | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                                               | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端直接使用 IPv4 地址建立连接                       | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                              |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4和1个 broken IPv6 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4和1个 broken IPv6 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4和1个 broken IPv6 地址，客户端直接使用 IPv4 地址建立连接                                                                                                                                                        | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4和1个 broken IPv6 地址，客户端直接使用 IPv4 地址建立连接                | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                              |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，无法完成连接                                                                                                                          | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，无法完成连接                                                                                                                          | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，无法完成连接                                                                                                                                           | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，无法完成连接   | 客户端只发起 A 记录解析请求，DNS服务器返回1个 broken IPv4 地址，客户端无法完成连接                                        | 客户端只发起 A 记录解析请求，DNS服务器返回1个 broken IPv4 地址，客户端无法完成连接                                                                                                                                                 |
| 客户端同时发起 AAAA 和 A 记录解析请求，客户端直接使用 IPv4 地址建立连接                                                                                                                                                                                    | 客户端同时发起 AAAA 和 A 记录解析请求，客户端直接使用 IPv4 地址建立连接                                                                                                                                                                                    | 客户端同时发起 AAAA 和 A 记录解析请求，客户端直接使用 IPv4 地址建立连接                                                                                                                                                                                                     | 客户端同时发起 AAAA 和 A 记录解析请求，客户端直接使用 IPv4 地址建立连接                                                             | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端只发起 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                              |
| 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先以顺序的形式对所有 IPv4 地址发起连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，等待client 超时后（设置为5s）连接未建立，对正常的 IPv4 地址发起连接，连接成功 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先以顺序的形式对所有 IPv4 地址发起连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，等待client 超时后（设置为5s）连接未建立，对正常的 IPv4 地址发起连接，连接成功 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先以顺序的形式对所有 IPv4 地址发起连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，根据传递给 urllib2.urlopen 的 timeout 时间(设置为1s)，1s后对正常的 IPv4 地址发起连接，连接成功 | 客户端同时发起 AAAA 和 A 记录解析请求，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端只使用 broken 地址发起连接，连接失败 | 客户端只发起 A 记录解析请求，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端只使用 broken 地址发起连接，连接失败 | 客户端只发起 A 记录解析请求，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，等待 proxy_connect_timeout（默认1m） 时间后连接未建立，再使用正常 IPv4 地址发起连接，连接成功，后续连接如此循环 |


## 4.2. Dual-stack

| go                                                                                                                                                                                                                                       | curl                                                                                                                                                                                                                       | python                                                                                                                                                                                                                                                                                      | node.js                                                                                                                             | java                                                                                                                                | nginx                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                          | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                            | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 地址，客户端直接使用该地址建立连接                                                                                                                                                    |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                                                                                                                          | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                                                                                                            | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                                                                                                                                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 地址，客户端直接使用该地址建立连接                                                                                                                                                    |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端首先使用 IPv4 地址建立连接                                                                                                                            | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端随机使用IPv4 和 IPv6 地址建立连接                                                                                                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端首先使用 IPv6 地址建立连接                                                                                                                                                                               | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端首先使用 IPv4 地址建立连接                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端首先使用 IPv4 地址建立连接                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6和1个 IPv4 地址，客户端随机使用 IPv4 和 IPv6 地址建立连接                                                                                                                              |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端首先使用 IPv4 地址建立连接                                                                                                                    | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果使用 broken 的 IPv6 地址发起连接，200ms 后连接未建立，客户端使用 IPv4 地址建立连接                                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端首先使用 IPv6 地址建立连接，根据传递给 urllib2.urlopen 的 timeout 时间(设置为1s)，1s IPv6 连接未建立，客户端再使用 IPv4 地址建立连接                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端首先使用 IPv4 地址建立连接               | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端首先使用 IPv4 地址建立连接               | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端随机使用 IPv4 和 IPv6 地址，如果使用了 broken 的 IPv6 地址，等待 proxy_connect_timeout（默认1m） 时间后连接未建立再使用 IPv4 建立连接                   |
| 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端首先使用 IPv4 地址建立连接，300ms IPv4 连接未建立，客户端再使用 IPv6 地址建立连接                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果使用 broken 的 IPv4 地址发起连接，200ms 后连接未建立，客户端使用 IPv6 地址建立连接                                                     | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端首先使用 IPv6 地址建立连接                                                                                                                                                                       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，连接失败       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv6 和1个 broken IPv4 地址，客户端只使用 IPv4 地址建立连接，连接失败       | 客户端同时发起 AAAA 和 A 记录解析请求，DNS服务器返回1个 IPv4 和1个 broken IPv6 地址，客户端随机使用 IPv4 和 IPv6 地址，如果使用了 broken 的 IPv4 地址，等待 proxy_connect_timeout（默认1m） 时间后连接未建立再使用 IPv6 建立连接                   |
| 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先使用 IPv4 地址建立连接                                                                                                                                                                  | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果 broken 的 IPv6 地址在排在正常的 IPv6 地址前，客户端首先使用 broken 地址发起连接，200ms 后连接未建立，客户端直接使用 IPv4 地址建立连接 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先以顺序的形式对所有 IPv6 地址发起连接，如果 broken 的 IPv6 地址在排在正常的 IPv6 地址前，客户端首先使用 broken 地址发起连接，根据传递给 urllib2.urlopen 的 timeout 时间(设置为1s)，1s IPv6 连接未建立，对正常的 IPv6 地址发起连接，连接成功 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先使用 IPv4 地址建立连接                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先使用 IPv4 地址建立连接                                                             | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果 broken 的 IPv6 地址在排在正常的 IPv6 地址前，客户端首先使用 broken 地址发起连接，等待proxy_connect_timeout（默认1m） 连接未建立，再使用正常 IPv6 地址发起连接 |
| 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先以顺序的形式对所有 IPv4 地址发起连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，等待 300ms 连接未建立，对正常的 IPv4 地址发起连接，连接成功 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，200ms 后连接未建立，客户端直接使用 IPv6 地址建立连接 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端首先使用 IPv6 地址建立连接                                                                                                                                                                                                                     | 客户端同时发起 AAAA 和 A 记录解析请求，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端只使用 broken 地址发起连接，连接失败 | 客户端同时发起 AAAA 和 A 记录解析请求，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端只使用 broken 地址发起连接，连接失败 | 客户端同时发起 AAAA 和 A 记录解析请求，客户端随机使用IPv4 和 IPv6 地址建立连接，如果 broken 的 IPv4 地址在排在正常的 IPv4 地址前，客户端首先使用 broken 地址发起连接，等待proxy_connect_timeout（默认1m） 连接未建立，再使用正常 IPv4 地址发起连接 |


# 5. 总结

**集群中主要存在以下集中域名解析请求：**
1. Kubernetes IPv6 service 域名
2. Kubernetes IPv4 service 域名
3. 特殊域名
4. 管理网服务域名
5. 科学上网域名
6. 外网域名

* 对于第 1、2 两类域名，coredns Kubernetes  插件可以根据 service 的类别只返回对应的 IPv6 或者 IPv4 地址；
* 对于第 3 类域名我们可以特殊配置 hosts，返回 IPv6 或 IPv4 地址；
* 对于第 4 类域名，管理网服务可能不支持 IPv6，dns 服务器也不能直接探测管理网服务是否支持 IPv6，所以dns服务器返回 IPv4 地址和 6to4 地址，由客户端使用 Happy Eyeballs 算法进行连接竞速选择可用的服务地址，如果 IPv6 是不可达、不存在的地址或者没有listen对应的端口，那么连接竞速会快速完成，不会等待连接尝试延迟时间(go默认 300ms)；如果 IPv6 包被丢了，客户端可能会等待尝试延迟时间后再对另一个地址族发起连接，某些客户端比如 nginx 需要设置 proxy_connect_timeout，python urllib2.urlopen 需要设置timeout 时间，不然建立连接很慢；
* 对于第 5、6 类地址由于集群现在只支持通过 IPv6 访问公网，所以直接返回 IPv6 地址；

# 6. 附录
## 6.1. 客户端测试代码
### 6.1.1. go

```go
package main

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"
)

const (
	defaultHttpClientTimeout = 5 * time.Second
)

var (
	httpReqTimeoutFlag = flag.Duration("timeout", defaultHttpClientTimeout, "Connection and read timeout value (for http)")
	numConnFlag        = flag.Int("c", 1, "Number of connections per host")
)

func main() {
	if len(os.Args) < 2 {
		usageErr("Error: need at least 1 command parameter")
	}

	flag.Parse()

	var client runner

	fmt.Println("Use Http for dr testing")
	client = newHttpClient()

	if res, err := client.do("first"); err != nil {
		fmt.Printf("Error: query failed, %v\n", err)
	} else {
		fmt.Printf("Info: receive response, %s\n", res)
	}
}

// Prints usage and error messages with StdErr writer.
func usageErr(msgs ...interface{}) {
	fmt.Println(msgs...)
	os.Exit(1)
}

type runner interface {
	do(string) (string, error)
}

type httpClient struct {
	url    string
	client *http.Client
}

func newHttpClient() runner {
	url := strings.TrimLeft(flag.Arg(0), " \t\r\n")

	timeout := httpReqTimeoutFlag
	transport := http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
		//DisableKeepAlives:   false,
		MaxConnsPerHost:     *numConnFlag,
		MaxIdleConns:        *numConnFlag,
		MaxIdleConnsPerHost: *numConnFlag,
	}

	client := &http.Client{
		Transport: &transport,
		Timeout:   *timeout,
	}
	return &httpClient{
		url:    url,
		client: client,
	}
}

func (c *httpClient) do(payload string) (string, error) {
	req, err := http.NewRequest("GET", c.url, bytes.NewBufferString(time.Now().String()+"--"+payload))
	if err != nil {
		return "", err
	}

	resp, err := c.client.Do(req)
	if resp != nil {
		defer resp.Body.Close()
	}
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf(
			"error get health information about Grafana, expected status 200 but got %v",
			resp.StatusCode)
	}

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
```

### 6.1.2. getaddrinfo

```c
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

void printAddr(const struct sockaddr * res);

int
main(int argc, char * argv[]) {
    struct addrinfo hints;
    struct addrinfo * result, * rp;
    int s;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s host port...\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    
    memset( & hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC; /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM; /* Stream socket */
    hints.ai_flags = (AI_CANONNAME | AI_V4MAPPED | AI_ALL);
    //hints.ai_flags = 0;
    //hints.ai_protocol = 0;          /* Any protocol */

    s = getaddrinfo(argv[1], argv[2], & hints, & result);
    if (s != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
        exit(EXIT_FAILURE);
    }

    /* getaddrinfo() returns a list of address structures.*/

    for (rp = result; rp != NULL; rp = rp -> ai_next) {
        printf("Received ai_family:%d ai_socktype:%d ai_protocol:%d ai_addrlen:%d\n",
            rp -> ai_family, rp -> ai_socktype, rp -> ai_protocol, rp -> ai_addrlen);
        printAddr(rp -> ai_addr);
    }

    freeaddrinfo(result); /* No longer needed */

    exit(EXIT_SUCCESS);
}

void printAddr(const struct sockaddr * res) {
    char * s = NULL;
    switch (res -> sa_family) {
    case AF_INET: {
        struct sockaddr_in * addr_in = (struct sockaddr_in * ) res;
        s = malloc(INET_ADDRSTRLEN);
        inet_ntop(AF_INET, & (addr_in -> sin_addr), s, INET_ADDRSTRLEN);
        break;
    }
    case AF_INET6: {
        struct sockaddr_in6 * addr_in6 = (struct sockaddr_in6 * ) res;
        s = malloc(INET6_ADDRSTRLEN);
        inet_ntop(AF_INET6, & (addr_in6 -> sin6_addr), s, INET6_ADDRSTRLEN);
        break;
    }
    default:
        break;
    }
    printf("IP address: %s\n", s);
    free(s);
}
```

### 6.1.3. python

```python
#!/usr/bin/python

import urllib
import urllib2

url = 'http://www.example.org:8080'
values = {'name' : 'Michael'}
data = urllib.urlencode(values)
req = urllib2.Request(url, data)
response = urllib2.urlopen(req,timeout=1)
print response.read()
6.1.4. node.js
var http = require('http');

var options = {
  host: 'www.example.org',
  path: '/',
  port: '8080',
  method: 'POST'
};

callback = function(response) {
  var str = ''
  response.on('data', function (chunk) {
    str += chunk;
  });

  response.on('end', function () {
    console.log(str);
  });
}

var req = http.request(options, callback);
req.write("hello world!");
req.end();
6.1.5. java
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class GetRequestJava11 {

    public static void main(String[] args) throws IOException, InterruptedException {

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://www.example.org:8080/"))
                .build();

        HttpResponse<String> response = client.send(request,
                HttpResponse.BodyHandlers.ofString());

        System.out.println(response.body());
    }
}
6.1.6. nginx
server {
    listen       [::]:9901;
    listen       0.0.0.0:9901;
    server_name  localhost;

    location / {
        proxy_pass   http://www.example.org:8080;
    }
}

upstream myserver {
    server  www.example.org:8080;
}

server {
    listen       [::]:9902;
    listen       0.0.0.0:9902;
    server_name  localhost;

    location / {
        proxy_pass   http://myserver;
    }
}
```

原文链接： https://www.yuque.com/dogbrother-5valv/tzhl7q/rpuusg#tImdq

# 参考文献

https://tools.ietf.org/html/rfc3484
https://tools.ietf.org/html/rfc6724
https://tools.ietf.org/html/rfc6555
https://tools.ietf.org/html/rfc8305