FROM cloudtrust-baseimage:f27

ARG redis_service_git_tag
ARG config_git_tag
ARG config_repo

###
###  Prepare the system stuff
###

RUN dnf -y install redis && \
    dnf clean all

RUN install -d -v -m755 /var/lib/redis -o redis -g redis && \
    install -d -v -m755 /var/lib/redis/data -o redis -g redis && \
    install -d -v -m755 /var/lib/redis/log -o redis -g redis

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/redis-service.git && \
    git clone ${config_repo} ./config

WORKDIR /cloudtrust/redis-service
RUN git checkout ${redis_service_git_tag}

WORKDIR /cloudtrust/redis-service
RUN install -v -m0644 deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m0644 deploy/etc/monit.d/* /etc/monit.d/

###
###  Redis
###

WORKDIR /cloudtrust/redis-service
RUN install -v -o root -g root -m 644 -d /etc/systemd/system/redis.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/redis.service.d/limit.conf /etc/systemd/system/redis.service.d/limit.conf

##
##  Config
##

WORKDIR /cloudtrust/config
RUN git checkout ${config_git_tag}

WORKDIR /cloudtrust/config
RUN install -v -m0755 -o redis -g redis deploy/etc/redis/redis.conf /etc/redis.conf

##
##  Enable services
##

RUN systemctl enable redis.service && \
    systemctl enable monit.service

VOLUME ["/var/lib/redis"]

EXPOSE 6379
