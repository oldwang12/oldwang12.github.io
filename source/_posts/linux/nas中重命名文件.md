---
layout: linux
title: nas中重命名文件
date: 2023-08-08 16:29:04
tags: [shell,nas,alist]
categories: linux
---

{% note primary%}

目前使用该脚本来将 alist 中某个项目下的文件由 xx.1.xx 改为 xx.01.xx

{% endnote %}

<!-- more -->

```sh
#!/bin/bash

dir=$1  # 指定目录路径

# 进入目录
cd "$dir" || exit

# 替换文件名中的abcd1至abcd9为abcd01至abcd09
for file in *S01E[1-9].*; do
  new_file=$(echo "$file" | sed 's/S01E\([1-9]\)/S01E0\1/')
  echo $new_file
  mv "$file" "$new_file"
done
```
