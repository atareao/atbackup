FROM alpine:3.20

LABEL maintainer="Lorenzo Carbonell <a.k.a. atareao> lorenzo.carbonell.cerezo@gmail.com"

RUN apk add --update \
            --no-cache \
            openssh~=9.7 \
            tzdata~=2024 \
            curl~=8.8 \
            borgbackup~=1.2 \
            mariadb-client~=10.11 \
            jq~=1.7 \
            fuse~=2.9 \
            dcron~=4.5 \
            run-parts~=4.11 && \
    rm -rf /var/cache/apk && \
    rm -rf /var/lib/app/lists* && \
    mkdir -p /root/.ssh

COPY run.sh backup.sh /

WORKDIR "/cronitab"

CMD ["/bin/sh", "/run.sh"]
