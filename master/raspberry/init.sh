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
    h) echo "init.sh -e [ETHERNET ADAPATER NAME] -f (set if first master node) -h (help)"
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
cat << EOF > /tmp/${HOSTNAME}/kubeadminitcfg.yaml
apiVersion: "kubeadm.k8s.io/v1alpha1"
kind: MasterConfiguration
etcd:
  endpoints:
  - https://${IP}:2379
  caFile: /etc/kubernetes/pki/etcd/ca.crt
  certFile: /etc/kubernetes/pki/etcd/healthcheck-client.crt
  keyFile: /etc/kubernetes/pki/etcd/healthcheck-client.key
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
if [ ! "$FIRST" = "TRUE" ]; then
    if [ ! -f /etc/kubernetes/pki/sa.crt  ]; then
        echo "/etc/kubernetes/pki/sa.crt not found!"
        echo "Copy from other master, or if first master, use -f flag!"
        echo "On other master: scp /etc/kubernetes/pki/ca.* [this user]@${IP}:~/."
        echo "On other master: scp /etc/kubernetes/pki/sa.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        exit
    fi

    if [ ! -f /etc/kubernetes/pki/sa.key  ]; then
        echo "/etc/kubernetes/pki/sa.key not found!"
        echo "Copy from other master, or if first master, use -f flag!"
        echo "On other master: scp /etc/kubernetes/pki/ca.* [this user]@${IP}:~/."
        echo "On other master: scp /etc/kubernetes/pki/sa.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        exit
    fi
    if [ ! -f /etc/kubernetes/pki/sa.crt  ]; then
        echo "/etc/kubernetes/pki/sa.crt not found!"
        echo "Copy from other master, or if first master, use -f flag!"
        echo "On other master: scp /etc/kubernetes/pki/ca.* [this user]@${IP}:~/."
        echo "On other master: scp /etc/kubernetes/pki/sa.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        exit
    fi
    if [ ! -f /etc/kubernetes/pki/sa.key  ]; then
        echo "/etc/kubernetes/pki/sa.key not found!"
        echo "Copy from other master, or if first master, use -f flag!"
        echo "On other master: scp /etc/kubernetes/pki/ca.* [this user]@${IP}:~/."
        echo "On other master: scp /etc/kubernetes/pki/sa.* [this user]@${IP}:~/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        echo "On this node: cd ~;sudo chown root:root sa.*;sudo cp sa.* /etc/kubernetes/pki/."
        exit
    fi

fi
kubeadm init --config=/tmp/${HOSTNAME}/kubeadminitcfg.yaml --ignore-preflight-errors= | tee kubeadminit.out

echo "Kubeadm init output can be found in kubeadminit.out"
echo "Check status by by running: kubectl get nodes --kubeconfig=/etc/kubernetes/admin.conf"
echo "Status should be 'NotReady' for latest added node if no network is configured"
