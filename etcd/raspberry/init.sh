#!/bin/bash
  
if (( $EUID != 0 )); then
    echo "Please run with sudo"
    exit
fi

while getopts e:fh option 
do
    case "${option}" 
    in
    e) ETHERNET=${OPTARG};;
    f) FIRST="TRUE";;
    h) echo "init.sh -e [ETHERNET ADAPATER NAME] -f (set if first etcd node) -h (help)"
       exit;;
    esac
done

if [ -z "$ETHERNET"  ]; then
    echo "Please configure ethernet adapater using -e flag"
    exit
fi


HOSTNAME=$(hostname)
IP=$(ifconfig "$ETHERNET" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'  | cut -f2 -d " ")
mkdir -p /tmp/${HOSTNAME}
cat << EOF > /tmp/${HOSTNAME}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1alpha1"
kind: MasterConfiguration
etcd:
    serverCertSANs:
    - "${IP}"
    peerCertSANs:
    - "${IP}"
    extraArgs:
        initial-cluster: ${HOSTNAME}=https://${IP}:2380
        initial-cluster-state: new       
        name: ${HOSTNAME}
        listen-peer-urls: https://0.0.0.0:2380
        listen-client-urls: https://0.0.0.0:2379
        advertise-client-urls: https://${IP}:2379
        initial-advertise-peer-urls: https://${IP}:2380
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
nodeName: ${HOSTNAME}
endpoint-reconciler-type: lease
EOF
mkdir -p /etc/kubernetes/pki/
if [ "$FIRST" = "TRUE" ]; then
    kubeadm alpha phase certs etcd-ca
else
    if [ ! -f /etc/kuberenetes/pki/etcd/ca.crt  ]; then
        echo "/etc/kuberenetes/pki/etcd/ca.crt not found!"
        echo "Copy from other etcd node, or if first etcd node, use -f flag!"
        echo "On other master: scp /etc/kuberenetes/pki/etcd/ca.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root ca.*;sudo cp ca.* /etc/kuberenetes/pki/etcd/."
        exit
    fi
    if [ ! -f /etc/kuberenetes/pki/etcd/ca.key  ]; then
        echo "/etc/kuberenetes/pki/etcd/ca.key not found!"
        echo "Copy from other etcd node, or if first etcd node, use -f flag!"
        echo "On other master: scp /etc/kuberenetes/pki/etcd/ca.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root ca.*;sudo cp ca.* /etc/kuberenetes/pki/etcd/."
        exit
    fi

fi
kubeadm alpha phase certs etcd-server --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-peer --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml

docker build -t etcd:arm32 ..

docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd etcd:arm32 etcd --initial-advertise-peer-urls=https://${IP}:2380 --initial-cluster=${HOSTNAME}=https://${IP}:2380 --initial-cluster-state=new --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${HOSTNAME} --advertise-client-urls=https://${IP}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt



