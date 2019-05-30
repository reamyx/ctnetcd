#官方centos7镜像初始化,镜像TAG: ctnetcd

FROM        imginit
LABEL       function="ctnetcd"

#添加本地资源
ADD     etcd     /srv/etcd/

WORKDIR /srv/etcd

#功能软件包
RUN     set -x \
        && cd ../imginit \
        && mkdir -p installtmp \
        && cd installtmp \
        \
        && curl -L https://github.com/etcd-io/etcd/releases/download/v3.3.12/etcd-v3.3.12-linux-amd64.tar.gz \
           -o etcd-v3.3.12-linux-amd64.tar.gz \
        && tar -zxvf etcd-v3.3.12-linux-amd64.tar.gz \
        && cd etcd-v3.3.12-linux-amd64 \
        && \cp -f etcd etcdctl /usr/bin \
        && cd - \
        && curl -L https://github.com/evildecay/etcdkeeper/releases/download/0.7.2/etcdkeeper-v0.7.2-linux_x86_64.zip \
           -o etcdkeeper-v0.7.2-linux_x86_64.zip \
        && unzip etcdkeeper-v0.7.2-linux_x86_64.zip \
        && chmod +x etcdkeeper/etcdkeeper \
        && mv etcdkeeper /srv \
        \
        && cd ../ \
        && rm -rf installtmp /tmp/* \
        && find ../ -name "*.sh" -exec chmod +x {} \;

ENV       ZXDK_THIS_IMG_NAME    "ctnetcd"
ENV       SRVNAME               "etcd"

# ENTRYPOINT CMD
CMD [ "../imginit/initstart.sh" ]
