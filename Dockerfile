# 使用 Node 14 作为基础镜像
FROM node:16

# 创建工作目录
WORKDIR /app

RUN \
    npm install -g hexo-cli

# 将 Hexo 相关文件复制到容器中
COPY . .

# 安装 Hexo 的依赖
# RUN npm install

# 声明 Hexo 服务的运行端口（根据您的 Hexo 配置进行相应修改）
EXPOSE 4000

# 启动 Hexo 服务
CMD ["hexo", "server"]