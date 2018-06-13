Execute the following command on a raspian strecth installation
First set unique hostname by running, use menu
If this is the first node 
Use this as input when adding more etcd and master nodes

"2 Network options"

    sudo raspi-config

Or run 
    
    sudo bash init.sh
    shutdown -r now

All command should be executed as root

    sudo su

Install Docker
    
    curl -sSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    usermod -aG docker pi

Install Kubernetes    
    
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
    deb http://apt.kubernetes.io/ kubernetes-xenial main
    EOF

    apt-get update && apt-get install -y apt-transport-https
    apt-get install -y kubelet kubeadm kubectl
    apt-get install git

Needed by kubernetes networking
    
    sysctl net.bridge.bridge-nf-call-iptables=1

Install crictl
    
    wget https://storage.googleapis.com/golang/go1.10.linux-armv6l.tar.gz
    tar -C /usr/local -xzf go1.10.linux-armv6l.tar.gz
    export PATH=$PATH:/usr/local/go/bin

    export GOPATH=~/go
    go get github.com/kubernetes-incubator/cri-tools/cmd/crictl
    cp $GOPATH/bin/crictl /usr/local/bin

Disable swap
    
    dphys-swapfile swapoff
    dphys-swapfile uninstall
    update-rc.d dphys-swapfile remove

Enable cgroup
    
    orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=memory"
    echo $orig >> /boot/cmdline.txt

Reboot
    
    shutdown -r now



