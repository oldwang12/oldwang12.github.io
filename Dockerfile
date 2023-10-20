FROM docker.io/oldwang6/node:16.hexo
WORKDIR /root
COPY . .
EXPOSE 4000
CMD ["hexo", "server"]