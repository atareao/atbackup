FROM alpine:3.20

LABEL maintainer="Lorenzo Carbonell <a.k.a. atareao> lorenzo.carbonell.cerezo@gmail.com"

ENV HOME=/cronitab

RUN apk add --update \
            --no-cache \
            tzdata~=2024 \
            tar~=1.35 \
            dcron~=4.5 \
            run-parts~=4.11 && \
    rm -rf /var/cache/apk && \
    rm -rf /var/lib/app/lists*

COPY run.sh backup.sh /

WORKDIR "$HOME"

CMD ["/bin/sh", "/run.sh"]
