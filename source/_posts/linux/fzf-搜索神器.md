---
title: fzf-搜索神器
category: linux
date: 2023-08-17 15:12:07
updated:
tags: [linux,fzf]
---
{% note primary%}

模糊搜索神器

{% endnote %}

<!-- more -->

## 1. 配合history
```sh
history | fzf | awk '{print $2}' | xargs -r -I {} sh -c "{}"
```

## 2. 搜索到文件后查看内容
```sh
ls -l | fzf | awk '{print $9}' | xargs -r -I {} sh -c "cat {}"
```

## 3. 查看git提交状态
```sh
git log --oneline | fzf | awk '{print $1}' | xargs -r -I {} git show {}
```
