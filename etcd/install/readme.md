Install, configure and start first etcd node

    sudo bash init.sh -e eth0 -f

Install, configure and start second or later etcd nodes

    sudo bash init.sh -e eth0

Use other network adapter, like wlan0, replace parameter to -e
Example:

    sudo bash init.sh -e wlan0

Check status if etcd, should be no restarts

    docker ps

Explanation of script

Gets IP of machine
    IP=$(ifconfig "$ETHERNET" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'  | cut -f2 -d " ")

Set ip to configuration for cert generation
    
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

Generate CA certs for first master node

    if [ "$FIRST" = "TRUE" ]; then
        kubeadm alpha phase certs etcd-ca

Generate etcd certs

    kubeadm alpha phase certs etcd-server --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
    kubeadm alpha phase certs etcd-peer --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml
    kubeadm alpha phase certs etcd-healthcheck-client --config=/tmp/${HOSTNAME}/kubeadmcfg.yaml

Build and start etcd docker on Raspberry

    docker build -t etcd:arm32 ..

    docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd etcd:arm32 etcd --initial-advertise-peer-urls=https://${IP}:2380 --initial-cluster=${HOSTNAME}=https://${IP}:2380 --initial-cluster-state=new --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${HOSTNAME} --advertise-client-urls=https://${IP}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt

But on x86... this is used instead

    docker run --restart always -d --net host -v /etc/kubernetes:/etc/kubernetes -v /var/lib/etcd:/var/lib/etcd quay.io/coreos/etcd:v3.2.14 etcd  --initial-advertise-peer-urls=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster=${NODENAME}=https://${ADVERTISE_ADDRESS}:2380 --initial-cluster-state=new --listen-client-urls=https://0.0.0.0:2379 --listen-peer-urls=https://0.0.0.0:2380 --name=${NODENAME} --advertise-client-urls=https://${ADVERTISE_ADDRESS}:2379 --client-cert-auth=true --data-dir=/var/lib/etcd --key-file=/etc/kubernetes/pki/etcd/server.key --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-client-cert-auth=true --cert-file=/etc/kubernetes/pki/etcd/server.crt --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
