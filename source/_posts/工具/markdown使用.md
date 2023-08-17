---
layout: 工具
title: Markdown使用
date: 2023-08-16 16:39:49
tags: [markdown,fluid,hexo]
categories: 工具
sticky: 999
# index_img: /img/titles/markdown.png
---

{% note warning%}

有一些语法可能只能在 hexo fluid 主题中使用。

{% endnote %}

<!-- more -->

## 1. 文本颜色
```md
<span style="color: green;">green</span>
<span style="color: red;">red</span>
```

## 2. 页面内实现目录
```md
### 目录
[1. 章节1](#1)

<!-- 这里 p 标签必须和下面一行隔开 -->
<p id="1"></p>
```

## 3. 标签

### 3.1 便签
参考：https://fluid-dev.github.io/hexo-fluid-docs/guide/#tag-%E6%8F%92%E4%BB%B6

在 markdown 中加入如下的代码来使用便签：

```md
{% note success %}
文字 或者 `markdown` 均可
{% endnote %}
```
或者使用 HTML 形式：
```html
<p class="note note-primary">标签</p>
```
可选便签：

{% note primary %}
primary
{% endnote %}

{% note secondary %}
secondary
{% endnote %}

{% note success %}
success
{% endnote %}

{% note danger %}
danger
{% endnote %}

{% note warning %}
warning
{% endnote %}

{% note info %}
info
{% endnote %}

{% note light %}
light
{% endnote %}

### 3.2 行内标签

在 markdown 中加入如下的代码来使用 Label：

{% label primary @text %}

```md
{% label primary @text %}
```
或者使用 HTML 形式：

```html
<span class="label label-primary">Label</span>
```

可选 Label：

{% label primary @primary %}
{% label default @default %}
{% label info @info %}
{% label success @success %}
{% label warning @warning %}
{% label danger @danger %}



{% note warning %}
警告：

若使用 {% label primary @text %}，text 不能以 @ 开头
{% endnote %}

### 3.3 勾选框

在 markdown 中加入如下的代码来使用 Checkbox：

```md
{% cb text, checked?, incline? %}
```

- text：显示的文字
- checked：默认是否已勾选，默认 false
- incline: 是否内联（可以理解为后面的文字是否换行），默认 false

示例：

{% cb 普通示例 %}
{% cb 默认选中, true %}
{% cb 内联示例, false, true %} 后面文字不换行
{% cb false %} 也可以只传入一个参数，文字写在后边（这样不支持外联）

<p></p>

示例代码：
```md
{% cb 普通示例 %}
{% cb 默认选中, true %}
{% cb 内联示例, false, true %} 后面文字不换行
{% cb false %} 也可以只传入一个参数，文字写在后边（这样不支持外联）
```

## 4. 文章概要
```md
<!-- more -->
```