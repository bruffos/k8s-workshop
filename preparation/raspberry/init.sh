#!/bin/bash
  
if (( $EUID != 0 )); then
    echo "Please run with sudo"
    exit
fi

curl -sSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker pi

    
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update && apt-get install -y apt-transport-https
#version 1.10.[0-4]is not working, use latest 1.9.x release
apt-get install -y kubelet=1.9.8-00 kubeadm kubectl
apt-get install git

    
sysctl net.bridge.bridge-nf-call-iptables=1

wget https://storage.googleapis.com/golang/go1.10.linux-armv6l.tar.gz
tar -C /usr/local -xzf go1.10.linux-armv6l.tar.gz
PATH=$PATH:/usr/local/go/bin

GOPATH=~/go
go get github.com/kubernetes-incubator/cri-tools/cmd/crictl
cp $GOPATH/bin/crictl /usr/local/bin

dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove

CMDLINE_UPDATED=$(grep "cgroup_enable=memory" /boot/cmdline)
if [ -z "$CMDLINE_UPDATED" ]; then
    orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory"
    echo $orig > /boot/cmdline.txt
fi

echo "Please reboot now: shutdown -r now"


