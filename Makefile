.PHONY: push help

push: ## 上传代码到 Github
	hexo generate
	hexo deploy
	git add .
	git commit -m "`date '+%Y/%m/%d %H:%M:%S'`"
	git push origin master

	echo "`date '+%Y/%m/%d %H:%M:%S'`" >> /Users/wangxiong/Desktop/github/projects/projects/blog/update.log

	cd /Users/wangxiong/Desktop/github/projects
	git add .
	git commit -m "更新博客"
	git push origin master

local: ## 本地编译镜像并运行
	docker build -t blog .
	docker rm -f blog
	docker run -itd -p 4000:4000 --name blog blog

help: ## 查看帮助
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)