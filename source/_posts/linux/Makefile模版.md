---
layout: linux
title: Makefile模版
date: 2023-07-23 00:15:50
tags: linux
---

```makefile
.PHONY: git_push docker_build all help

# 获取 git 项目 COMMIT_HASH
COMMIT_HASH = $(shell git rev-parse --short=7 HEAD)

git_push: ## 上传代码到 Github
	git add .
	git commit -m "`date '+%Y/%m/%d %H:%M:%S'`"
	git push origin dev

help: ## 查看帮助
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
```

#### 指定参数

```makefile
commit: 
	git commit -m "$(msg)"
```

使用如下

```sh
make commit msg="makefile 测试"              
```