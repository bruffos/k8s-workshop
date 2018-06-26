#!/bin/bash

if (( $EUID != 0 )); then
    echo "Please run with sudo"
    exit
fi

while getopts e:hm:c: option
do
    case "${option}"
    in
    e) ETHERNET=${OPTARG};;
    m) MASTER_HOST=${OPTARG};;
    c) CLUSTER_NODES=${OPTARG};;
    h) echo "init.sh -e [ETHERNET ADAPATER NAME] -m  [IP/Hostname of etcd master] -c [other cluster nodes name=ip:port,name2:ip:port] -h (help)"
       exit;;
    esac
done


if [ "$MASTER_HOST" ]; then
    if [ -z "$CLUSTER_NODES" ]; then
        echo "Please configure cluster nodes if configure master host using -c flag"
        exit
    fi
fi

if [ -z "$ETHERNET"  ]; then
    echo "Please configure ethernet adapater using -e flag"
    exit
fi


CPU_ARCHITECTURE=$(lscpu | awk '/Architecture/{print $2}')
HOSTNAME=$(hostname)
NODENAME=$(echo ${HOSTNAME//.})
EXTERNAL_IP=$(dig +noall +answer $HOSTNAME | awk /$HOSTNAME/'{print $5}' | head -1)
IP=$(ifconfig "$ETHERNET" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'  | cut -f2 -d " ")
ADVERTISE_ADDRESS=${IP}

#if [[ $EXTERNAL_IP =~ ^127.* ]]; then
#else
#    ADVERTISE_ADDRESS=${HOSTNAME}
#fi
mkdir -p /tmp/${HOSTNAME}
cat << EOF > /tmp/${HOSTNAME}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1alpha1"
kind: MasterConfiguration
etcd:
    serverCertSANs:
    - "${ADVERTISE_ADDRESS}"
    peerCertSANs:
    - "${ADVERTISE_ADDRESS}"
    extraArgs:
        initial-cluster: ${NODENAME}=https://${ADVERTISE_ADDRESS}:2380
        initial-cluster-state: new
        name: ${NODENAME}
        listen-peer-urls: https://0.0.0.0:2380
        listen-client-urls: https://0.0.0.0:2379
        advertise-client-urls: https://${ADVERTISE_ADDRESS}:2379
        initial-advertise-peer-urls: https://${ADVERTISE_ADDRESS}:2380
api:
  advertiseAddress: ${IP}
  bindPort: 6443
authorizationModes:
- Node
- RBAC
certificatesDir: /etc/kubernetes/pki
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
nodeName: ${NODENAME}
endpoint-reconciler-type: lease
EOF
mkdir -p /etc/kubernetes/pki/etcd/

if [ -z "$MASTER_HOST" ]; then
    kubeadm alpha phase certs etcd-ca
else
    if [ ! -f /etc/kubernetes/pki/etcd/ca.crt  ]; then
        echo "/etc/kubernetes/pki/etcd/ca.crt not found!"
        echo "Copy from other etcd node, or if first etcd node, use -f flag!"
        echo "On other master: sudo scp /etc/kubernetes/pki/etcd/ca.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root ca.*;sudo mv ca.* /etc/kubernetes/pki/etcd/."
        exit
    fi
    if [ ! -f /etc/kubernetes/pki/etcd/ca.key  ]; then
        echo "/etc/kubernetes/pki/etcd/ca.key not found!"
        echo "Copy from other etcd node, or if first etcd node, use -f flag!"
        echo "On other master: sudo scp /etc/kubernetes/pki/etcd/ca.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root ca.*;sudo mv ca.* /etc/kubernetes/pki/etcd/."
        exit
    fi
fi
kubeadm alpha phase certs etcd-server --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
if [ -z "$MASTER_HOST" ]; then

    if [[ $CPU_ARCHITECTURE =~ .*x86.* ]]; then
        docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd quay.io/coreos/etcd:v3.3 etcd  --initial-advertise-peer-urls=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster=${NODENAME}=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster-state=new --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${NODENAME} --advertise-client-urls=https://${ADVERTISE_ADDRESS}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    else
        docker build -t etcd:arm32 ..

        docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd etcd:arm32 etcd --initial-advertise-peer-urls=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster=${NODENAME}=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster-state=new --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${NODENAME} --advertise-client-urls=https://${ADVERTISE_ADDRESS}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    fi
else
    if [[ $CPU_ARCHITECTURE =~ .*x86.* ]]; then
        docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:v3.3 etcdctl --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --ca-file /etc/kubernetes/pki/etcd/ca.crt --endpoints https://${MASTER_HOST}:2379 member add ${NODENAME} https://${ADVERTISE_ADDRESS}:2380
  
        docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd quay.io/coreos/etcd:v3.3 etcd  --initial-advertise-peer-urls=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster=${NODENAME}=https://${ADVERTISE_ADDRESS}:2380,${CLUSTER_NODES} --initial-cluster-state=existing --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${NODENAME} --advertise-client-urls=https://${ADVERTISE_ADDRESS}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    else
        docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd etcd:arm32 etcdctl --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --ca-file /etc/kubernetes/pki/etcd/ca.crt --endpoints https://${MASTER_HOST}:2379 member add ${NODENAME} https://${ADVERTISE_ADDRESS}:2380
  
        docker build -t etcd:arm32 ..

        docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd etcd:arm32 etcd --initial-advertise-peer-urls=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster=${NODENAME}=https://${ADVERTISE_ADDRESS}:2380,${CLUSTER_NODES} --initial-cluster-state=existing --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${NODENAME} --advertise-client-urls=https://${ADVERTISE_ADDRESS}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    fi
fi
