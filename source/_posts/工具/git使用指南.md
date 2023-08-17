---
layout: 工具
title: git使用指南
date: 2023-08-16 10:36:30
tags: [工具,git]
categories: 工具
---

## 1. 一键提交当前分支
```sh
git add .;git commit -m "test";git push origin $(git symbolic-ref --short HEAD)
```

## 2. 开发分支落后时，如何同步 master 分支。
```sh
# 1. 获取master分支的最新变更。可以使用以下命令来更新您本地的master分支
git checkout master
git pull origin master

# 2. 切换回开发分支，并将master分支的变更合并到开发分支上：
git checkout feature/test
git merge master

# 3. 如果有冲突出现，您需要解决这些冲突后再提交变更。

# 4. 推送开发分支到远程仓库
git push origin feature/test
```