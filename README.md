#### 1. 本地上传

```sh
make msg="xxx"                      
```

#### 2. 博客新建文件
```sh
hexo new k8s pod网络
```

#### 3. 本地运行
```sh
hexo s
```

#### 4. workflows

cat docker-image.yml

```yml
name: 编译镜像

on:
  push:
    branches: ["master"]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Login to Docker Hub
        run: docker login --username=${{ secrets.HUB_USERNAME }} registry.cn-hangzhou.aliyuncs.com -p ${{ secrets.HUB_PASSWORD }}

      - name: 编译镜像
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: registry.cn-hangzhou.aliyuncs.com/breawang/blog:latest

      - name: 连接服务器
        uses: webfactory/ssh-agent@v0.5.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

      - name: 执行命令
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_IP }}
          username: ${{ secrets.SERVER_USERNAME }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            # 在这里编写你想要在服务器上执行的命令
            kubectl -n cai rollout restart deployment blog
```
