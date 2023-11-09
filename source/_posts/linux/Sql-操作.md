---
title: Sql 操作
category: linux
date: 2023-08-28 18:55:08
tags: sql
categories: linux
---
{% note primary%}

sql整理

{% endnote %}

## 1. Mysql
### 1.1. 删除数据库
```
drop database <数据库名>;
```
### 1.2. 创建表
```
CREATE TABLE table_name (column_name column_type)
```
### 1.3. 插入数据
```
INSERT INTO table_name ( field1, field2,...fieldN ) values( value1, value2,...valueN );
```
### 1.4. 更新数据
```
UPDATE table_name SET field1=new-value1, field2=new-value2 [WHERE Clause]
```
### 1.5. 删除数据
```
DELETE FROM table_name [WHERE Clause]
```
### 1.6. like
address 表中获取 domain 字段中以 COM 为结尾的的所有记录
```
select * from address where domain like '%COM';
```
### 1.7. order by (排序)
```
select * from table order by age ASC;
```
ASC: 升序       DESC:降序

默认为 ASC
### 1.8. alert
| Field | Type    | Null | Key | Default | Extra |
| ----- | ------- | ---- | --- | ------- | ----- |
| i     | int(11) | YES  |     | NULL    |       |
| c     | char(1) | YES  |     | NULL    |       |

```
 alert table leesin  drop i;    删除表的 i 字段
 alert table leesin  aaa i INT; 增加表的 i 字段
```
### 1.9. mysqldump (mysql 外部执行)
```
mysqldump -u <user> -h <host> -P <port> -p<passward> <table> > text.sql
```
### 1.10. 导入 DB
```
mysql -u <user> -h <host> -P <port> -p<passward> <table> < text.sql
```

## 2. Postgres

### 2.1. 备份
```sh
pg_dumpall -U postgres > /var/lib/postgresql/dump.sql
```

### 2.2. 恢复
```sh
psql -U postgres -f /var/lib/postgresql/dump.sql
```

### 2.3. 删除数据库
```sh
dropdb -U postgres postgres
```

### 2.4. 新建数据库
```sh
createdb  -U postgres postgres
```

### 2.5. 新增apikey
```sql
INSERT INTO apikey (name, count, statu, used, valid)
VALUES ('sk-xx', 0, 't', 'f', 't');
INSERT 0 1
```