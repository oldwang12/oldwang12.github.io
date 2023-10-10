---
layout: k8s
title: 使用kubeadm安装集群
date: 2023-07-26 10:09:12
tags: k8s
categories: k8s
---

{% note primary%}

目前最主流的安装方式，使用kubeadm安装集群。

{% endnote %}

<!-- more -->

## 图解k8s
![master-worker](/img/master-worker.png)
## 1. containerd
**1.1 使用 tar 包安装**
[下载地址](https://github.com/containerd/containerd/releases)

```sh
wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /usr/local/lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd
```

**1.2 rpm、deb 包安装**
- Centos [下载地址](https://download.docker.com/linux/centos/7/x86_64/stable/Packages/)
- Ubuntu [下载地址](https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64)

## 2. runc

[下载地址](https://github.com/opencontainers/runc/releases)

```sh
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc
```

## 3. ctrctl

[下载地址](https://github.com/kubernetes-sigs/cri-tools/releases)

```sh
# 注意: 下载对应的集群版本，crictl版本列表：https://github.com/kubernetes-sigs/cri-tools/tags
VERSION="v1.26.0" # check latest version in /releases page
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz
```

### 3.1 containerd 配置
```sh
crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
```
### 3.2 ctrctl 报错文件找不到
* 不同的部署方式，文件路径可能不同。

```sh
# 以 k3s 为例，指定 .sock 文件
crictl --runtime-endpoint /var/run/k3s/containerd/containerd.sock ps -a
```

### 3.3 查看 ctrctl 配置
```sh
cat /etc/crictl.yaml
```

## 4. kubeadm、kubelet、kubectl
```sh
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"

# 安装最新版
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

# 安装指定版本
# RELEASE="v1.26.7"

ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}

RELEASE_VERSION="v0.15.1"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 激活并启动 kubelet
systemctl enable --now kubelet
```

## 5. conntrack
```sh
yum install conntrack-tools -y
```

**测试**
```sh
conntrack -L
```

## 6. 设置内核参数

{% note primary %}
如果不设置参数，使用 kubeadm join 时可能会导致报错。
{% endnote %}

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

### 6.1 加载 bridge 内核模块

查看是否加载 br_netfilter 模块
```sh
lsmod | grep br_netfilter
```

如果没加载执行
```sh
sudo modprobe br_netfilter
```

### 6.2 更改内核参数

打开 /etc/sysctl.conf 文件

```sh
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

#### 6.3 重新加载 sysctl 配置
```sh
sysctl -p
```

## 7. 部署集群

### 7.1 master
```sh
kubeadm init --v=5 --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.28.2
```

此时，正常情况下你应该看到master安装成功提示
```log
kubeadm join 10.7.130.29:6443 --token kqi9ve.dvcyddrn9527rvnu \
	--discovery-token-ca-cert-hash sha256:67c19abd79fhjkl1cc5a04e2192bf3bc335d41f2f4a76084adcc4cda3d48804
```

将master设置为node
```sh
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### 7.2 node
```sh
kubeadm join 10.7.130.29:6443 --token kqi9ve.dvcyddrn9527rvnu \
	--discovery-token-ca-cert-hash sha256:67c19abd79fhjkl1cc5a04e2192bf3bc335d41f2f4a76084adcc4cda3d48804
```
### 7.3 参数说明
```sh
# 指定版本
--kubernetes-version=v1.28.2

# 指定镜像源为阿里
--image-repository registry.cn-hangzhou.aliyuncs.com/google_containers

# 指定pod网段
--pod-network-cidr=10.244.0.0/16
```

### 7.4 重新生成 token

当忘记kubeadm join命令时，可以重新生成token。以此来获得 kubeadm join 命令。

```sh
sudo kubeadm token create --print-join-command
```
### 7.5 查看 token
```sh
sudo kubeadm token list
```

## 8. kubeconfig 配置文件
默认生成的 kubeconfig 文件在 /etc/kubernetes/admin.conf

```sh
mkdir $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
kubectl get no
```

## 9. 安装网络插件
{% note danger %}
不安装官方插件会报错，忘记了什么原因导致的。
{% endnote %}

### 9.1 先安装官方插件
[下载地址](https://github.com/containernetworking/plugins/releases)
```sh
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
tar -zxvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin
rm -f cni-plugins-linux-amd64-v1.3.0.tgz
```
### 9.2 安装 flannel 或 calico
```sh
# flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
```sh
# calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

安装完{% label default @cni %}后，此时{% label default @coredns %}应该为 {% label success @running %}

#### 9.2.1 查看flannel模式

{% label success @flannel %} 默认的模式为 {% label primary @vxlan %}，如果需要修改，可以修改 {% label default @configmap %}  {% label default @kube-flannel-cfg %}

```sh
kubectl -n kube-flannel get configmap kube-flannel-cfg -oyaml
```

#### 9.2.2 创建测试pod
```sh
kubectl run my-pod --image=nginx:latest
```