---
layout: linux
title: cronjob 定时任务
date: 2023-08-01 15:49:05
tags: linux
---
#### cronjob 定时任务
```sh
# crontab -e 命令以编辑当前用户的cron表。
crontab -e

# 每分钟执行一次 ls
*/1 * * * * ls
```