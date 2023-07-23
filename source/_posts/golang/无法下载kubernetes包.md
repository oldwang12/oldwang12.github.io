---
layout: golang
title: Golang 无法下载kubernetes包
date: 2023-07-23 00:11:45
tags: golang
---

如果我们直接 go get k8s.io/kubernetes@v1.19.2 下载依赖，会出现以下错误:

```go
go get k8s.io/kubernetes@v1.19.2
go: downloading k8s.io/kubernetes v1.19.2
go: k8s.io/kubernetes@v1.19.2 requires
        k8s.io/api@v0.0.0: reading k8s.io/api/go.mod at revision v0.0.0:
```

错误的原因是在kubernetes主仓中，也使用了公共库，不过go.mod文件中所有公共库版本都指定为了v0.0.0（显然这个版本不存在）， 然后通过Go Module的replace机制，将版本替换为子目录./staging/src/k8s.io对应的依赖。

保存内容为 go-get-kubernetes.sh, 执行 ./go-get-kubernetes.sh v1.19.2，会自动在go.mod中替换。
```sh
#!/bin/sh
set -euo pipefail

VERSION=${1#"v"}
if [ -z "$VERSION" ]; then
    echo "Must specify version!"
    exit 1
fi
MODS=($(
    curl -sS https://raw.githubusercontent.com/kubernetes/kubernetes/v${VERSION}/go.mod |
    sed -n 's|.*k8s.io/\(.*\) => ./staging/src/k8s.io/.*|k8s.io/\1|p'
))
for MOD in "${MODS[@]}"; do

    V=$(
        go mod download -json "${MOD}@kubernetes-${VERSION}" |
        sed -n 's|.*"Version": "\(.*\)".*|\1|p'
    )
    go mod edit "-replace=${MOD}=${MOD}@${V}"
done
go get "k8s.io/kubernetes@v${VERSION}"
```

