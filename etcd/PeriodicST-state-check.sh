#!/bin/env sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"; cd "$(dirname "$0")"
exec 4>&1; ECHO(){ echo "${@}" >&4; }; exec 3<>"/dev/null"; exec 0<&3;exec 1>&3;exec 2>&3

#服务状态测试
pidof "etcd" && {
    [ -f "./EtcdKeeper.Enabled" ] && { pidof "etcdkeeper" || exit; }
    exit 0; }
