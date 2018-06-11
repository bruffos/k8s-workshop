#!/bin/sh
kubectl create secret generic mosquitto-cacerts --from-file=secrets/cacerts
kubectl create secret generic mosquitto-certs --from-file=secrets/certs
kubectl create secret generic mosquitto-acl --from-file=secrets/acl

