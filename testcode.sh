#!/bin/env sh
exit 0

#ETCD集群成员 etcd193
SRVCFG='{"initdelay":2,"workstart":"./etcdstart.sh",
"workwatch":15,"workintvl":5,
"firewall":{"tcpportpmt":"2379,2380","icmppermit":"yes"},
"etcd":{"name":"etcd193","discovery-srv":"srvrcd.local"}}'; \
docker stop etcd193; docker rm etcd193; \
docker container run --detach --restart always \
--name etcd193 --hostname etcd193 \
--network imvn --cap-add NET_ADMIN \
--device /dev/ppp --device /dev/net/tun \
--volume /etc/localtime:/etc/localtime:ro \
--volume /srv/etcdstore:/srv/etcd/etcdstore \
--ip 192.168.15.193 --dns 192.168.15.192 --dns-search local \
--env "SRVCFG=$SRVCFG" ctnetcd

docker container exec -it etcd193 bash


#节点替换:  检查原节点ID:cluster-health
#           移除原节点:member remove $ID
#           添加新节点:member add etcd194 "http://etcd194:2380"
#           新节点使用initial-cluster-state="existing"启动

#ETCD集群成员 etcd194
#同时启用etcdkeeper: http://192.168.15.194:2378/etcdkeeper/
rm -rf /srv/etcdstore; \
EXIST=',"initial-cluster-state":"existing"' \
SRVCFG='{"initdelay":2,"workstart":"./etcdstart.sh",
"workwatch":15,"workintvl":5,
"firewall":{"tcpportpmt":"2379,2380","icmppermit":"yes"},
"etcd":{"name":"etcd194","discovery-srv":"srvrcd.local" },
"etcdkeeper":{"enable":"yes","srvport":""}}'; \
docker stop etcd194; docker rm etcd194; \
docker container run --detach --restart always \
--name etcd194 --hostname etcd194 \
--network imvn --cap-add NET_ADMIN \
--device /dev/ppp --device /dev/net/tun \
--volume /etc/localtime:/etc/localtime:ro \
--volume /srv/etcdstore:/srv/etcd/etcdstore \
--ip 192.168.15.194 --dns 192.168.15.192 --dns-search local \
--env "SRVCFG=$SRVCFG" ctnetcd

docker container exec -it etcd194 bash

#ETCD集群成员 etcd195
SRVCFG='{"initdelay":2,"workstart":"./etcdstart.sh",
"workwatch":15,"workintvl":5,
"firewall":{"tcpportpmt":"2379,2380","icmppermit":"yes"},
"etcd":{"name":"etcd195","discovery-srv":"srvrcd.local"}}'; \
docker stop etcd195; docker rm etcd195; \
docker container run --detach --restart always \
--name etcd195 --hostname etcd195 \
--network imvn --cap-add NET_ADMIN \
--device /dev/ppp --device /dev/net/tun \
--volume /etc/localtime:/etc/localtime:ro \
--volume /srv/etcdstore:/srv/etcd/etcdstore \
--ip 192.168.15.195 --dns 192.168.15.192 --dns-search local \
--env "SRVCFG=$SRVCFG" ctnetcd

docker container exec -it etcd195 bash
