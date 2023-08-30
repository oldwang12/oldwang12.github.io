---
layout: linux
title: linux 命令大全
date: 2023-08-16 14:40:47
tags: linux
categories: linux
sticky: 1000
---

{% note primary%}

分为文件操作、网络管理、系统管理、进程管理、安全性来归纳linux基本使用

{% endnote %}

<!-- more -->


# 1. 文件操作
## 文件权限
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

## 解压、压缩

### 解压
```sh
tar -xzvf test.tar.gz
```
### 压缩
```sh
tar -czvf test.tar.gz README.md
```

### 解压到指定文件夹
```sh
tar -xzvf test.tar.gz -C /home/test
```
### 列出压缩文件内容
```sh
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

### 使用密码

```sh
# 将当前目录下的files文件夹打包压缩，密码为password
# -iter 10000参数来指定迭代次数为10000次。这将提高密钥派生的强度，增加加密的安全性。
tar -czvf - files | openssl des3 -salt -k password  -iter 10000 -out files.tar.gz

# 将当前目录下的files.tar.gz进行解密解压
openssl des3 -d -salt -k password -iter 10000 -in files.tar.gz | tar -xzf -
```

### 分割文件

```sh
# 分割
split -b 1M file.tar.gz file_bakcup.

# 合并
cat file_backup* > file.tar.gz
```

## 软、硬链接

删除源文件，硬链接没有影响，软链接不可用。

### 软链接
```sh
ln -s README.md README.soft.md
```

### 硬链接
```sh
ln README.md README.hard.md
```

## 内存、cpu、io

### 内存

1. 输入 `top` 命令，按下 `M` 键可以按照内存使用量进行排序。
2. 查看内存使用最多的5个进程

```sh
ps aux --sort=-%mem | head -n 6
```

#### 查看指定进程内存占用

ps -o rss= -p <pid>

### CPU

1. 输入 `top` 命令，按下 `P` 键可以按照内存使用量进行排序。
2. 查看CPU使用最多的5个进程

```sh
ps aux --sort=-%cpu | head -n 6
```

### IO

{% note warning %}
请注意，`iotop` 和 `pidstat` 可能需要先安装，在终端输入以下命令可以安装它们：
{% endnote %}

```sh
# centos
yum -y install iotop

# ubuntu
apt-get install iotop sysstat
```
#### iotop
{% label primary @iotop %} 命令可以 {% label danger @实时 %} 显示系统中进程的磁盘IO使用情况。打开终端并输入 iotop 命令，然后按下O键可以按照IO使用量进行排序。按q可以退出iotop 命令
   
#### pidstat
{% label success @pidstat %} 命令可以显示特定进程的IO使用情况。输入以下命令来查看IO使用最多的5个进程：

```sh
pidstat -d | sort -nrk 2 | head -n 6
```

#### iostat
{% label primary @iostat %} 命令可以提供关于系统设备和分区的IO统计信息。输入以下命令来查看整个系统的IO情况：

```sh
# 瞬时数据
iostat -d

# 每隔5s采样一次
iostat -d -t 5

# 输出
Linux 4.19.xxx.x86_64 (10-11-xx-xx) 	202x年0x月1x日 	_x86_64_	(2 CPU)

Device:            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
vda               2.70        19.13        36.54  102409528  195610326
```

{% note warning %}

设备名称：显示连接到系统的硬盘和存储设备的设备名称。

tps（Transactions Per Second）：每秒处理的 I/O 事务数。

kB_read/s 和 kB_wrtn/s：每秒从设备读取和写入的数据量（以 KB 为单位）。

kB_read 和 kB_wrtn：自系统启动以来已经读取和写入的总数据量（以 KB 为单位）。

kB_read/s 和 kB_wrtn/s：每秒从设备读取和写入的数据量（以 KB 为单位）。

svctm（Service Time）：每个 I/O 操作花费的平均时间。

%util：设备使用率的百分比，即设备每秒钟的 I/O 请求占总容量的百分比。
{% endnote %}


## top
### 前五行

![Alt text](top-01.png)

#### 1. 输出系统任务队列信息

{% note warning %}

**10:38:45**：系统当前时间 
**up 2days 18:57**：系统开机后到现在的总运行时间
**1 user**：当前登录用户数
**load average**: 0.10, 0.12, 0.09：系统负载，系统运行队列的平均利用率，可认为是可运行进程的平均数；三个数值分别为 1分钟、5分钟、15分钟前到现在的平均值；单核CPU中load average的值=1时表示满负荷状态，多核CPU中满负载的load average值为1*CPU核数
{% endnote %}

#### 2. 任务进程信息

{% note warning %}
**total**：系统全部进程的数量
**running**：运行状态的进程数量
**sleeping**：睡眠状态的进程数量
**stoped**：停止状态的进程数量
**zombie**：僵尸进程数量
{% endnote %}

#### 3. CPU信息

{% note warning %}
**us**：用户空间占用CPU百分比
**sy**：内核空间占用CPU百分比
**ni**：已调整优先级的用户进程的CPU百分比
**id**：空闲CPU百分比，越低说明CPU使用率越高
**wa**：等待IO完成的CPU百分比
**hi**：处理硬件中断的占用CPU百分比
**si**：处理软中断占用CPU百分比
**st**：虚拟机占用CPU百分比
{% endnote %}

#### 4. 物理内存信息

{% note warning %}
以下内存单位均为MB

在 top 命令界面上，可以按下 e 键来进入设置界面，然后按下 E 键来切换内存单位为 GB。你可以在 top 的设置界面中选择其他显示选项，按需进行更改。

在设置界面中，你也可以使用 W 命令将当前的设置保存为个人配置文件，以便下次启动 top 时自动应用这些设置。

**total**：物理内存总量
**free**：空闲内存总量
**used**：使用中内存总量
**buff/cache**：用于内核缓存的内存量
{% endnote %}

#### 5. 交互区内存信息

swap 分区通常被称为交换分区，这是一块特殊的硬盘空间，即当实际内存不够用的时候，操作系统会从内存中取出一部分暂时不用的数据，放在交换分区中，从而为当前运行的程序腾出足够的内存空间。

{% note warning %}
**total**：交换区总量
**free**：空闲交换区总量
**used**：使用的交换区总量
**avail Mem**：可用交换区总量
{% endnote %}


### 进程列表

![进程列表](top-02.png)
{% note warning %}
**PID**：进程号
**USER**：运行进程的用户
**PR**：优先级
**NI**：nice值。负值表示高优先级，正值表示低优先级
**VIRT**：占用虚拟内存，单位kb。VIRT=SWAP+RES 
**RES**：占用真实内存，单位kb
**SHR**：共享内存大小，单位kb
**S**：进程状态（I=空闲状态，R=运行状态，S=睡眠状态，D=不可中断的睡眠状态，T=跟踪/停止，Z=僵尸进程）
**%CPU**：占用CPU百分比
**%MEM**：占用内存百分比
**TIME+**：上次启动后至今的总运行时间
**COMMAND**：命令名or命令行
{% endnote %}

### 使用方法
#### 更换内存单位
{% note warning %}
在 top 命令界面上，可以按下 e 键来进入设置界面，然后按下 E 键来切换内存单位为 GB。你可以在 top 的设置界面中选择其他显示选项，按需进行更改。

在设置界面中，你也可以使用 W 命令将当前的设置保存为个人配置文件，以便下次启动 top 时自动应用这些设置。
{% endnote %}

## 磁盘

### du
{% note warning %}

直接输入 du 没有加任何选项时，则 du 会分析当前所在目录里的子目录所占用的硬盘空间。

Mac 上使用 `du -s` 输出大小可能是正常的2倍，至于为什么，暂不清楚。Mac 可以使用 `du -hd1` 查看

{% endnote %}

选项与参数：

-a ：列出所有的文件与目录容量，因为默认仅统计目录底下的文件量而已。
-h ：以人们较易读的容量格式 (G/M) 显示；
-s ：列出总占用量；
-S ：不包括子目录下的总计，与 -s 有点差别。
-k ：以 KBytes 列出容量显示；
-m ：以 MBytes 列出容量显示；

```sh
# 查看指定目录
du -sh .
3.8G	.
# ====================================

# 查看指定目录下的所有文件大小，深度为1
du -h $DIR --max-depth=1 | sort -h

# 部分输出
...
388M	./k3s
570M	./.npm
1.4G	./CAI.bak
3.8G	.

# ====================================
# 参数解析
# --max-depth 深度
# sort -h 从小到大排序
# sort -rh 从大到小排序
```

#### 

### df

显示系统中每个文件系统的磁盘使用情况

```sh
df -h
```

### lsblk

显示系统中所有的块设备，包括硬盘和分区。通常，系统盘的挂载点是根目录 /，而数据盘则可能挂载在其他目录上，如/home、/mnt等。

```sh
lsblk
```

显示所有在启动时挂载的文件系统，包括系统盘和数据盘的信息。一般情况下，系统盘的挂载信息会在此文件中。
   
```sh
cat /etc/fstab
```

### fdisk

列出所有分区信息

```sh
fdisk
```

### mount

{% note warning %}
目的：向linux系统新增一块硬盘，并挂载到指定目录。
{% endnote %}

1. 进入设备分区

lsblk 查看对应的磁盘名称，比如为 vdb。
   
```sh
fdisk /dev/vdb
```

2. 进入交互终端后，使用 n 命令创建新分区。根据提示，选择主分区类型（p）。

3. 提供分区号。

4. 提供新分区的结束位置。输入 +250G 以指定分区大小为250GB。默认为全部。

5. 使用 p 命令确认分区表是否正确。

6. 使用 w 命令保存新的分区表。

7. 格式化分区

```sh
mkfs.ext4 /dev/vdb1
mkfs.ext4 /dev/vdb2
```

8. 创建两个挂载点。运行以下命令：

```sh
sudo mkdir /mnt/partition1
sudo mkdir /mnt/partition2
```

9. 挂载分区
    
```sh
sudo mount /dev/vdb1 /mnt/partition1
sudo mount /dev/vdb2 /mnt/partition2
```

10.  开机自动挂载

```sh
vim /etc/fstab

/dev/vdb1   /mnt/partition1   ext4   defaults   0   0
/dev/vdb2   /mnt/partition2   ext4   defaults   0   0
```

## 命令行快捷键
{% note warning %}
请注意，某些快捷键可能会因终端和操作系统的不同而有所差异。
{% endnote %}

| 快捷键        | 操作                                           |
| ------------- | ---------------------------------------------- |
| Ctrl + 左右键 | 在单词之间跳转                                 |
| Ctrl + a      | 跳到本行的行首                                 |
| Ctrl + e      | 跳到页尾                                       |
| Ctrl + u      | 删除当前光标前面的文字 （还有剪切功能）        |
| Ctrl + k      | 删除当前光标后面的文字 （还有剪切功能）        |
| Ctrl + L      | 进行清屏操作                                   |
| Ctrl + y      | 粘贴 Ctrl+u 或 Ctrl+k 剪切的内容               |
| Ctrl + w      | 删除光标前面的单词的字符（以空格隔开的字符串） |
| Alt + d       | 由光标位置开始，往右删除单词，往行尾删         |
| Ctrl + r      | 搜索执行过的命令                               |
| ! + 字符      | 快速执行最近执行过的命令，其中包含该字符       |
| history       | 显示部分历史命令                               |


# 2. 网络管理

## 端口查看

### netstat

{% note success %}

netstat、lsof、nmap可能漏掉某些端口，最直接的就是使用 curl 或者 telnet。

{% endnote %}

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

### lsof

```sh
lsof -i :30001
```

### telnet
```sh
telnet 127.0.0.1 30001
```
## 路由

**查看默认路由表信息**
```sh
ip r
ip -6 r
route
```

**查看路由表信息**
```sh
ip rule
ip -6 rule 
ip rule list
```

**查看走哪条路由**
```sh
ip route get 8.8.8.8
```

**路由追踪**
```sh
traceroute 8.8.8.8
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

**查看日志**
```sh
tail -f /var/spool/mail/root
```
# 5. 安全性

## 更换密码
```sh
passwd
```