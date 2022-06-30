#!/bin/bash

KUBECONFIG=~/.kube/cluster-test.yaml

ROLE="node-role.kubernetes.io/control-plane"

NODES=`kubectl --kubeconfig=$KUBECONFIG get nodes -o wide -l $ROLE=true -no-headers=true -o=jsonpath='{range .items[*]}{@.metadata.name}={@.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'`

BACKEND1=$''
BACKEND2=$''

for NODE in $NODES
do
    NAME=`echo $NODE | awk -F"=" '{print $1}'`
    IP=`echo $NODE | awk -F"=" '{print $2}'`    
    
    BACKEND1+="  server $NAME $IP:443 check check-ssl verify none\n"
    BACKEND2+="  server $NAME $IP:6443 check check-ssl verify none\n"

done

HAPROXYCFG=`cat haproxy.template.cfg`

HAPROXYCFG="${HAPROXYCFG/__BACKEND1__/$BACKEND1}"
HAPROXYCFG="${HAPROXYCFG/__BACKEND2__/$BACKEND2}"

echo -e "${HAPROXYCFG}" > /etc/haproxy/haproxy.cfg

systemctl restart haproxy.service
