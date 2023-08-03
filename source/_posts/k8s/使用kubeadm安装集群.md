---
layout: k8s
title: 使用kubeadm安装集群
date: 2023-07-26 10:09:12
tags: k8s
---

#### containerd

[下载地址](https://github.com/opencontainers/runc/releases)

```sh
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /usr/local/lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd
```

#### runc

[下载地址](https://github.com/opencontainers/runc/releases)

```sh
https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
```

#### kubeadm、kubelet、kubectl
```sh
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}

RELEASE_VERSION="v0.15.1"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

激活并启动 kubelet
```sh
systemctl enable --now kubelet
```

#### ctrctl

[下载地址](https://github.com/kubernetes-sigs/cri-tools/releases)

```sh
# 注意: 下载对应的集群版本，crictl版本列表：https://github.com/kubernetes-sigs/cri-tools/tags
VERSION="v1.26.0" # check latest version in /releases page
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz
```

###### ctrctl 测试
* 不同的部署方式，文件路径可能不同。

```sh
# 指定 .sock 文件
crictl --runtime-endpoint /var/run/k3s/containerd/containerd.sock ps -a
```

###### 默认配置
```sh
cat /etc/crictl.yaml
```

#### conntrack

```sh
yum install conntrack-tools -y
```

测试
```sh
conntrack -L
```

#### 内核参数

如果不设置参数，使用 kubeadm join 时可能会导致报错
```log
W0726 10:29:26.474684    8216 checks.go:1064] [preflight] WARNING: Couldn't create the interface used for talking to the container runtime: crictl is required by the container runtime: executable file not found in $PATH
	[WARNING FileExisting-socat]: socat not found in system path
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR FileExisting-crictl]: crictl not found in system path
	[ERROR FileExisting-conntrack]: conntrack not found in system path
	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
	[ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
```

1. 启用 IP 转发
```sh
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```

2. 打开 /etc/sysctl.conf 文件，更改内核参数
   
```
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

3. 加载 bridge 内核模块
```sh
lsmod | grep br_netfilter
sudo modprobe br_netfilter
sysctl -p
```

4. 重新加载 sysctl 配置

```sh
sysctl -p
```


# 未完。。。