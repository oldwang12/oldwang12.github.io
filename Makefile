.PHONY: push help

#	zip -qr themes/pure.zip themes/pure

push: ## 上传代码到 Github
	hexo generate
	hexo deploy
	git add .
	git commit -m "$(msg)"
	git push origin master

help: ## 查看帮助
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)