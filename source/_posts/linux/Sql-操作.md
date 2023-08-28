---
title: Sql 操作
category: linux
date: 2023-08-28 18:55:08
tags: sql
categories: linux
---

## Postgres

### 备份
```sh
pg_dumpall -U postgres > /var/lib/postgresql/dump.sql
```

### 恢复
```sh
psql -U postgres -f /var/lib/postgresql/dump.sql
```

### 删除数据库
```sh
dropdb -U postgres postgres
```

### 新建数据库
```sh
createdb  -U postgres postgres
```
