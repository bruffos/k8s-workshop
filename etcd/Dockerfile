FROM scratch

ENV ETCD_UNSUPPORTED_ARCH=arm

ADD etcd /usr/local/bin/etcd

EXPOSE 2379 2380

# Define default command.
CMD ["/usr/local/bin/etcd"]
