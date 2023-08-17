---
layout: 工具
title: chrome浏览器如何屏蔽无效请求
date: 2023-07-23 00:19:00
tags: 工具
categories: 工具
---

{% note primary%}

在 F12 调试时很不方便，故屏蔽掉不相关的请求。

{% endnote %}

<!-- more -->
#### 如何屏蔽掉无用的网络请求
```
-/.*.js|.*.php|.*.png|.*.ico|.*.css|.*.gif/
```