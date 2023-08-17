---
layout: linux
title: linux 命令大全
date: 2023-08-16 14:40:47
tags: linux
categories: linux
sticky: 1000
---

分为文件操作、网络管理、系统管理、进程管理、安全性来归纳linux基本使用
<!-- more -->


# 1. 文件操作
## 查看文件权限
```sh
# 以数字形式输出文件权限，0644
stat -c '%a' example.txt
```

```sh
ls -l example.txt

# 输出将类似于以下内容：
-rw-r--r-- 1 user group 12345 Jan 1 10:00 example.txt

# 在这个示例中，-rw-r--r--表示文件的权限。
# 第一个字符表示文件类型，- 表示普通文件。剩余的九个字符分为三组，每组三个字符表示所有者、所属组和其他人的权限。
# 每组中的三个字符表示读（r）、写（w）和执行（x）权限。如果对应位置有权限，字符表示对应的权限，否则用 - 来表示缺少权限。
# 在这个例子中，-rw-r--r-- 表示文件所有者有读、写权限，所属组和其他人只有读权限。
```

## 命令行快捷键
{% note warning %}
请注意，某些快捷键可能会因终端和操作系统的不同而有所差异。
{% endnote %}

| 快捷键        | 操作                                       |
| ------------ | ---------------------------------------- |
| Ctrl + 左右键  | 在单词之间跳转                                 |
| Ctrl + a     | 跳到本行的行首                                 |
| Ctrl + e     | 跳到页尾                                    |
| Ctrl + u     | 删除当前光标前面的文字 （还有剪切功能）                  |
| Ctrl + k     | 删除当前光标后面的文字 （还有剪切功能）                  |
| Ctrl + L     | 进行清屏操作                                  |
| Ctrl + y     | 粘贴 Ctrl+u 或 Ctrl+k 剪切的内容                 |
| Ctrl + w     | 删除光标前面的单词的字符（以空格隔开的字符串）             |
| Alt + d     | 由光标位置开始，往右删除单词，往行尾删                  |
| Ctrl + r     | 搜索执行过的命令                                |
| ! + 字符     | 快速执行最近执行过的命令，其中包含该字符                    |
| history      | 显示部分历史命令                                |


## 解压、压缩
```sh
# 压缩
tar -czvf test.tar.gz README.md

# 解压
tar -xzvf test.tar.gz

# 解压到指定文件夹
tar -xzvf test.tar.gz -C /home/test

# 列出压缩文件内容
tar -tzvf test.tar.gz 
```
{% note warning %}
**参数说明**
* -v 显示指令执行过程。
* -c 建立新的备份文件。
* -f 指定备份文件。
* -z 通过gzip指令处理备份文件。
* -x 从备份文件中还原文件。
{% endnote %}

**加密压缩**
```sh
# 将当前目录下的files文件夹打包压缩，密码为password
tar -czvf - files | openssl des3 -salt -k password -out files.tar.gz

# 将当前目录下的files.tar.gz进行解密解压
openssl des3 -d -k password -salt -in files.tar.gz | tar xzvf -
```

## du命令

```sh
# 只能查看文件夹

# 查看当前目录
du -h --max-depth=1 | sort -h

# 查看指定目录
du -h $DIR --max-depth=1 | sort -h

# 参数解析
# --max-depth 深度
# sort -h 从小到大排序
# sort -rh 从大到小排序
```

## 查看磁盘

1. 显示系统中每个文件系统的磁盘使用情况

```sh
df -h
```

2. 显示系统中所有的块设备，包括硬盘和分区。通常，系统盘的挂载点是根目录 /，而数据盘则可能挂载在其他目录上，如/home、/mnt等。

```sh
lsblk
```

3. 显示所有在启动时挂载的文件系统，包括系统盘和数据盘的信息。一般情况下，系统盘的挂载信息会在此文件中。
   
```sh
cat /etc/fstab
```

# 2. 网络管理

## 查看网络连接信息
```sh
netstat -nplt
```
参数说明:

{% note warning %}
-n 将字母转化为数字

-p 显示进程相关信息

-l 列出状态为监听

-t 只查看tcp协议

-a 查看全部协议(netstat -an)
{% endnote %}


## 路由追踪
```sh
traceroute 8.8.8.8
```

## 查看路由表
```sh
ip rule
ip -6 rule 
ip rule list
```
## 查看默认路由表信息
```sh
ip r
ip -6 r
route
```

## 网速测试

**安装**
```sh
sudo yum - y install speedtest-cli

sudo apt install speedtest-cli

sudo pip3 install speedtest-cli
```

**执行 speedtest-cli**
```sh
$ speedtest-cli
Retrieving speedtest.net configuration...
Testing from Unknown (165.154.145.190)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by Enzu.com (Los Angeles, CA) [11654.37 km]: 3.173 ms
Testing download speed................................................................................
Download: 56.57 Mbit/s
Testing upload speed......................................................................................................
Upload: 34.54 Mbit/s
```
{% note warning %}
* MB：字节
* Mbit：比特

1 字节 = 8 bit，所以 1MB/s = 8Mbit/s。

下载网速为 1MB/s ，这里指的是网速每秒可以下载1M。
{% endnote %}

## 快速开启http服务

这将监听本地 80 端口，响应 OK
```sh
echo -e 'HTTP/1.1 200 OK\r\n\r\nOK' | sudo socat - TCP-LISTEN:80
```

# 3. 进程管理
# 4. 系统管理

## cronjob 定时任务
```sh
# crontab -e 命令以编辑当前用户的cron表。
crontab -e

# 每分钟执行一次 ls
*/1 * * * * ls
```
# 5. 安全性
