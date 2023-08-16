---
layout: 工具
title: git使用指南
date: 2023-08-16 10:36:30
tags: 工具
---

#### 一键提交当前分支
```sh
git add .;git commit -m "test";git push origin $(git symbolic-ref --short HEAD)
```