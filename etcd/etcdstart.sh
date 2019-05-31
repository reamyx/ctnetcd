#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"; cd "$(dirname "$0")"
exec 4>&1; ECHO(){ echo "${@}" >&4; }; exec 3<>"/dev/null"; exec 0<&3;exec 1>&3;exec 2>&3

ETKPEN="./EtcdKeeper.Enabled"

#先行服务停止
for ID in {1..20}; do pkill "^etcd$" || pkill "^etcdkeeper$" || break; sleep 0.5; done
rm -rf "$ETKPEN"; [ "$1" == "stop" ] && exit 0

#DDNS注册
DDNSREG="./PeriodicRT-ddns-update"
[ -f "$DDNSREG" ] && ( chmod +x "$DDNSREG"; setsid "$DDNSREG" & )

#环境变量未能提供配置数据时从配置文件读取
[ -z "$SRVCFG" ] && SRVCFG="$( jq -scM ".[0]|objects" "./workcfg.json" )"

#etcdkeeper配置数据
EKPSRV="$( echo "$SRVCFG" | jq -r ".etcdkeeper|.enable|strings" )"
KPPORT="$( echo "$SRVCFG" | jq -r ".etcdkeeper|.srvport|numbers" )"
KPPORT="${KPPORT:-2378}"
FWRLPM=( -p tcp -m tcp --dport "$KPPORT" -m conntrack --ctstate NEW -j ACCEPT )
iptables -t filter -D SRVLCH "${FWRLPM[@]}"

#etcd配置数据
SRVCFG="$( echo "$SRVCFG" | jq -cM ".etcd|objects" )"
PMETCD=(); KEY=""; VAL=""; DTDIR="./etcdstore"

#检查并在必要时添加必备参数
PMNEED=( "name" "data-dir" "listen-client-urls" "listen-peer-urls"
         "advertise-client-urls" "initial-advertise-peer-urls" )
PMKEYS=( $( echo "$SRVCFG" | jq -r "keys[]" ) )
for KEY in "${PMNEED[@]}"; do
    echo "${PMKEYS[*]}" | grep -Ewq "$KEY" || PMKEYS=( "${PMKEYS[@]}" "$KEY" ); done

#节点名称,数据目录
NDNM="$( echo "$SRVCFG" | jq -r ".\"name\"|strings" )"
JDIR="$( echo "$SRVCFG" | jq -r ".\"data-dir\"|strings" )"
NDNM="${NDNM:-$HOSTNAME-ind}"; DTDIR="${JDIR:-$DTDIR}"

#其它参数检查,跳过名称和目录配置
for KEY in "${PMKEYS[@]}"; do
    [ "$KEY" == "name" -o "$KEY" == "data-dir" ] && continue
    VAL="$( echo "$SRVCFG" | jq -r ".\"$KEY\"|strings" )"
    [ "$KEY" == "listen-client-urls" ] && VAL="${VAL:-http://0.0.0.0:2379}"
    [ "$KEY" == "listen-peer-urls"   ] && VAL="${VAL:-http://0.0.0.0:2380}"
    [ "$KEY" == "advertise-client-urls"       ] && VAL="${VAL:-http://$HOSTNAME:2379}"
    [ "$KEY" == "initial-advertise-peer-urls" ] && VAL="${VAL:-http://$HOSTNAME:2380}"
    [ -n "$VAL" ] && PMETCD=( "${PMETCD[@]}" "--$KEY" "$VAL" ); done

#非重启(不存在目标位置或标示文件)时清理可能的缓存
[ ! -f "$DTDIR/Etcd.Member.Name.$NDNM" ] && {
    mkdir -p "$DTDIR"; rm -rf "$DTDIR"/*; touch "$DTDIR/Etcd.Member.Name.$NDNM"; }

#根据配置启动etcdkeeper服务
[[ "$EKPSRV" =~ ^"YES"|"yes"$ ]] && {
    touch "$ETKPEN"; iptables -t filter -A SRVLCH "${FWRLPM[@]}"
    ( cd ../etcdkeeper; PATH="./:$PATH"; exec etcdkeeper -p "$KPPORT" )& }

#服务启动
exec etcd --name "$NDNM" --data-dir "$DTDIR" "${PMETCD[@]}"

exit 126

######################################################################################

#原有实例"重启"时只下列前5项亦可
etcd --name                   "$HOSTNAME" \
--data-dir                    "./etcdstore"  \
--listen-client-urls          "http://0.0.0.0:2379" \
--listen-peer-urls            "http://0.0.0.0:2380" \
--advertise-client-urls       "http://$HOSTNAME:2379" \
#初始化参数项
--discovery-srv               "srvrcd.local" \
--initial-cluster-token       "LV.QUJING" \
--initial-cluster-state       "new" \
--initial-advertise-peer-urls "http://$HOSTNAME:2380"

