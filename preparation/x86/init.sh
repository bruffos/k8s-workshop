#!/bin/bash
  
if (( $EUID != 0 )); then
    echo "Please run with sudo"
    exit
fi

#Might need to replace $(lsb_release -cs) with artful (ubuntu 17.10 when running on ubuntu 18.04)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   artful \
   stable"
apt-get install docker-ce


apt-get install golang

    
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update && apt-get install -y apt-transport-https
apt-get install -y kubelet kubeadm kubectl
apt-get install git

    
sysctl net.bridge.bridge-nf-call-iptables=1

GOPATH=~/go
go get github.com/kubernetes-incubator/cri-tools/cmd/crictl
cp $GOPATH/bin/crictl /usr/local/bin

swapoff -a
sed -i 's/\/swap/\#\/swap/g' /etc/fstab

CMDLINE_UPDATED=$(grep "cgroup_enable=memory" /etc/default/grub)
if [ -z "$CMDLINE_UPDATED" ]; then
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=cpuset cgroup_enable=memory"/g' /etc/default/grub 
fi

echo "Please reboot now: shutdown -r now"


