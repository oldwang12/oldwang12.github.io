---
layout: linux
title: nas整理
date: 2023-08-08 16:29:04
tags: [shell,nas,alist]
categories: linux
---

{% note primary%}

目前使用该脚本来将 alist 中某个项目下的文件由 xx.1.xx 改为 xx.01.xx

{% endnote %}

<!-- more -->

## 重命名
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

## 备份

### alist脚本

```sh
#!/bin/bash

# demo: bash tar.sh test test.tar.gz /local/data /百度网盘/数据冷备 http://localhost:5244 <alist-token>

# 判断参数个数是否为7个
if [ $# -ne 7 ]; then
  echo "Error: Expected 7 arguments."
  echo "Usage: $0 <filename> <src> <dst> <alist_host> <alist_token>"
  exit 1
fi

FILE_PATH=$1
FILE_NAME_TAR_GZ=$2
# 使用awk命令分割字符串并输出最后一个部分
FILE_NAME=$(echo $FILE_PATH | awk -F'/' '{print $NF}')
ALIST_SRC=$3
ALIST_DST=$4
ALIST_HOST=$5
ALIST_DATA_DIR=$6
ALIST_TOKEN=$7

if [ ! -e $FILE_PATH ]; then
    echo "文件不存在"
    exit 1
fi

# 以下是你希望执行的操作，当参数个数为三个时执行
echo "文件名: $FILE_NAME"
echo "打包文件名: $FILE_NAME_TAR_GZ"
echo "Alist src: $ALIST_SRC"
echo "Alist dst: $ALIST_DST"
echo "Alist Host: $ALIST_HOST"
echo "Alist Data dir: $ALIST_DATA_DIR"
echo "Alist Token: $ALIST_TOKEN"

# TIME=$(date +"%Y-%m-%d-%H%M")
# echo 当前时间: $TIME
# FILE_NAME_TAR_GZ="${TIME}-${FILE_NAME}.tar.gz"

echo 备份文件名: $FILE_NAME_TAR_GZ

echo "undone" > /root/tar_status.txt

# tar -czf $/{ALIST_DATA_DIR}/${FILE_NAME_TAR_GZ} $FILE_PATH
tar -cjf ${ALIST_DATA_DIR}/${FILE_NAME_TAR_GZ} $FILE_PATH

curl "$ALIST_HOST/api/fs/copy" \
  -H 'Accept: application/json, text/plain, */*' \
  -H "Authorization: $ALIST_TOKEN" \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json;charset=UTF-8' \
  -H "Origin: $ALIST_HOST" \
  -H "Referer: $ALIST_HOST/local/data" \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36' \
  -H 'sec-ch-ua: "Not/A)Brand";v="99", "Google Chrome";v="115", "Chromium";v="115"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw '{"src_dir":"'"$ALIST_SRC"'","dst_dir":"'"$ALIST_DST"'","names":["'"$FILE_NAME_TAR_GZ"'"]}' \
  --compressed

sleep 10
echo "done" > /root/tar_status.txt
```

### 压缩
```go
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path"
	"strings"
	"time"

	"github.com/robfig/cron"
	"gopkg.in/yaml.v2"
	"k8s.io/klog/v2"
)

type Config struct {
	Alist struct {
		Host    string `yaml:"host"`
		DataDir string `yaml:"data_dir"`
		Token   string `yaml:"token"`
	} `yaml:"alist"`

	CronTime         string `yaml:"cron_time"`
	TarShellFilePath string `yaml:"tar_shell_filepath"`

	Clouds []struct {
		Name      string   `yaml:"name"`
		Backup    bool     `yaml:"backup"`
		AlistSrc  string   `yaml:"alist_src"`
		AlistDst  string   `yaml:"alist_dst"`
		FilePaths []string `yaml:"filepaths"`
	} `yaml:"clouds"`
}

type RequestAlistUndone struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    []struct {
		Name string `json:"name"`
	} `json:"data"`
}

func main() {
	c := initConfig()

	klog.Info("checking... ")
	c.Check()

	var tarfilepath []string
	tarfilename := make(map[string]string)

	backup := func() {
		klog.Info("start backuping... ")
		for _, cloud := range c.Clouds {
			if !cloud.Backup {
				continue
			}
			for _, filepath := range cloud.FilePaths {
				startTime := time.Now()
				var tarfile string
				if tarfilename[filepath] == "" {
					tarfile = getTarfile(filepath)
				} else {
					tarfile = tarfilename[filepath]
				}

				klog.Infof("tarfile is %v", tarfile)
				if err := run(c.TarShellFilePath, filepath, tarfile, cloud.AlistSrc, cloud.AlistDst, c.Alist.Host, c.Alist.DataDir, c.Alist.Token); err != nil {
					klog.Errorf("[%v]: backup %v failed, %v", cloud.Name, tarfile, err)
					continue
				}

				// wait alist task done
				for {
					time.Sleep(5 * time.Second)
					if c.TaskDone() && c.TarDone() {
						klog.Infof("[%v]: backup %v success %v\n", cloud.Name, tarfile, time.Since(startTime))
						break
					}
				}
				tarfilepath = append(tarfilepath, path.Join(c.Alist.DataDir, tarfile))
				tarfilename[filepath] = tarfile
			}
		}
		fmt.Printf("\n")
	}

	remove := func() {
		for _, tarfile := range tarfilepath {
			if err := os.Remove(path.Join(c.Alist.DataDir, tarfile)); err != nil {
				klog.Warningf("delete %v failed", tarfile)
			}
		}
		// reset
		tarfilepath = []string{}
		tarfilename = make(map[string]string)
	}

	cronjob := cron.New()

	cronjob.AddFunc(c.CronTime, func() {
		if c.TaskDone() {
			backup()
			remove()
		}
	})

	cronjob.Start()

	stopCh := make(chan struct{})
	<-stopCh
}

func run(shellPath, filePath, tarfile, alistSrc, alistDst, alistHost, alistDataDir, alistToken string) error {
	klog.Info([]string{"sh", shellPath, filePath, tarfile, alistSrc, alistDst, alistHost, alistDataDir, alistToken})

	cmd := exec.Command("sh", shellPath, filePath, tarfile, alistSrc, alistDst, alistHost, alistDataDir, alistToken)
	_, err := cmd.Output()
	return err
}

func (c *Config) Check() {
	if c.Alist.Host == "" {
		panic("empty alist host")
	}

	if c.Alist.DataDir == "" {
		panic("empty alist data dir")
	}

	if c.Alist.Token == "" {
		panic("empty alist token")
	}
	if c.CronTime == "" {
		panic("empty cron time")
	}

	for _, cloud := range c.Clouds {
		if !cloud.Backup {
			continue
		}
		if cloud.AlistSrc == "" {
			panic(fmt.Sprintf("empty alist %v src", cloud.Name))
		}
		if cloud.AlistDst == "" {
			panic(fmt.Sprintf("empty alist %v dst", cloud.Name))
		}

		for _, v := range cloud.FilePaths {
			_, err := os.Stat(v)
			if os.IsNotExist(err) {
				panic(fmt.Sprintf("%v %v file not exist", cloud.Name, v))
			}
		}
	}
}

func initConfig() *Config {
	yamlFile, err := os.ReadFile("./config.yaml")
	if err != nil {
		panic(err)
	}

	config := Config{}
	if err := yaml.Unmarshal(yamlFile, &config); err != nil {
		panic(err)
	}
	return &config
}

func (c *Config) TarDone() bool {
	b, err := os.ReadFile("/root/tar_status.txt")
	if err != nil {
		klog.Error(err)
		return false
	}
	return string(b) == "done"
}

func (c *Config) TaskDone() bool {
	req, err := http.NewRequest("GET", fmt.Sprintf("%v/api/admin/task/copy/undone", c.Alist.Host), nil)
	if err != nil {
		klog.Error(err)
		return false
	}
	req.Header.Set("Authorization", c.Alist.Token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		klog.Error(err)
		return false
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		klog.Error(err)
		return false
	}

	response := RequestAlistUndone{}
	if err := json.Unmarshal(body, &response); err != nil {
		klog.Error(err)
		return false
	}
	return response.Code == 200 && len(response.Data) == 0
}

func getTarfile(filepath string) string {
	timelocal, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		panic(err)
	}
	time.Local = timelocal
	t := time.Now().Local().Format("2006-01-02_1504")
	filename := strings.Split(filepath, "/")[len(strings.Split(filepath, "/"))-1]
	// return fmt.Sprintf("%v-%v.tar.gz", t, filename)
	return fmt.Sprintf("%v-%v.tar.bz2", t, filename)
}
```

### 配置

```yaml
alist:
  data_dir: "/alist-data"
  host: "http://192.xxx.187.61:5244"
  token: "alist-e5630ef4-5fa2-4264-a256-323900236728"

cron_time: "0 40 18 * *"
tar_shell_filepath: "/root/tar.sh"

clouds:
  - name: 阿里云盘
    backup: false
    alist_src: "/本地/opt/alist/data" # 本地local盘
    alist_dst: "/阿里云盘/数据冷备"     # 本地阿里盘
    filepaths:                       # 备份哪些文件
    - "/Users/Desktop/github/blog"
    - "/Desktop/github/k3s"
  - name: 百度网盘
    backup: true
    alist_src: "/本地/opt/alist/data"
    alist_dst: "/百度网盘/数据冷备"
    filepaths:
    - "/data/歌曲"
```