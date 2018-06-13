Install, configure and start first master node

    sudo bash init.sh

Check kubeadminit.out for output of command

Explanation of script

Gets IP of machine

    IP=$(ifconfig "$ETHERNET" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'  | cut -f2 -d " ")

Generate kubeadm configuration

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

Init kubeadm

    kubeadm init --config=/tmp/${HOSTNAME}/kubeadminitcfg.yaml --ignore-preflight-errors= | tee kubeadminit.out
