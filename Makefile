.PHONY: push help

push: ## 上传代码到 Github
	docker buildx build --platform linux/arm -t registry.cn-hangzhou.aliyuncs.com/oldwang12/blog:latest -o type=registry .
	docker push registry.cn-hangzhou.aliyuncs.com/oldwang12/blog:latest
	hexo generate
	hexo deploy
	git add .
	git commit -m "`date '+%Y/%m/%d %H:%M:%S'`"
	git push origin master

local: ## 本地编译镜像并运行
	docker build -t blog .
	docker rm -f blog
	docker run -itd -p 4000:4000 --name blog blog

help: ## 查看帮助
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)