---
layout: 工具
title: git使用指南
date: 2023-08-16 10:36:30
tags: [工具,git]
categories: 工具
---

{% note primary%}

git 不仅仅是 pull 和 push。

{% endnote %}


<!-- more -->

## 1. 一键提交当前分支
```sh
git add .;git commit -m "test";git push origin $(git symbolic-ref --short HEAD)
```

## 2. 删除分支

```sh
# 删除本地分支
git branch -D xxx

# 删除远程分支
git push origin --delete xxx
```

## 3. 开发分支落后时，如何同步 master 分支。
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

## 4. git reset

放弃所有更改并回到上一次提交的状态：
```sh
git reset --hard HEAD^
```
{% note warning%}
这将删除所有的未提交更改，将HEAD指向父提交，并将工作区和暂存区恢复到上一次提交的状态。
{% endnote %}

保留更改但将其从暂存区中移除：
```sh
git reset HEAD
```

这将将所有已暂存的更改重置，但保留在工作区中，这样你就可以重新提交或进行进一步的更改。


{% note warning%}
请注意，git reset 是一个潜在的危险操作，因为它会从版本历史中移除提交。在执行这些命令之前，请确保你理解这些操作的副作用，并且在对你的代码产生重大影响之前，最好进行备份或咨询团队中的其他成员。
{% endnote %}