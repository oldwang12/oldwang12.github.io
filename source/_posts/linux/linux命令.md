---
layout: linux
title: linux命令
date: 2023-08-01 15:49:05
tags: linux
---
[1. cronjob 定时任务](#1)

<p id="1"></p>

#### cronjob 定时任务
```sh
# crontab -e 命令以编辑当前用户的cron表。
crontab -e

# 每分钟执行一次 ls
*/1 * * * * ls
```