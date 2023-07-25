.PHONY: git_push docker_build all help

push: ## 上传代码到 Github
	zip -qr themes/pure.zip themes/pure
	git add .
	git commit -m "`date '+%Y/%m/%d %H:%M:%S'`"
	git push origin dev

help: ## 查看帮助
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)
