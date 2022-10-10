FROM dexidp/dex:v2.35.2

LABEL org.opencontainers.image.title="dns3l auth"
LABEL org.opencontainers.image.description="An OIDC provider for DNS3L"
LABEL org.opencontainers.image.version=1.0.0

ENV VERSION=1.0.0

ENV PAGER=less

ARG http_proxy
ARG https_proxy
ARG no_proxy

# provided via BuildKit
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# defaults for none BuildKit
ENV _platform=${TARGETPLATFORM:-linux/amd64}
ENV _os=${TARGETOS:-linux}
ENV _arch=${TARGETARCH:-amd64}
ENV _variant=${TARGETVARIANT:-}

ENV DEXPATH="/home/dex"
ENV DEX_FRONTEND_DIR="/srv/dex/web"
ENV DEX="/srv/dex"

ARG DEXUID=10042
ARG DEXGID=10042

USER root
RUN apk --update upgrade && \
    apk add --no-cache \
        ca-certificates curl less bash busybox-extras \
        joe tzdata coreutils openssl \
        apache2-utils uuidgen && \
    addgroup -g ${DEXGID} dex && \
    adduser -D -u ${DEXUID} -G dex dex && \
    chmod g-s ${DEXPATH} && \
    chown dex:dex ${DEXPATH} && \
    rm -rf /var/cache/apk/*

# Install Mo Mustache
#
ENV MO_VERSION="2.2.0"
RUN curl -fsSL https://github.com/tests-always-included/mo/archive/$MO_VERSION.tar.gz | \
      tar -xO -zf- mo-$MO_VERSION/mo > /mo && \
    chmod a+x /mo

COPY --chown=dex:dex web/ ${DEXPATH}
COPY --chown=root:root config.docker.yaml /etc/dex/config.yaml.mustache
COPY --chown=root:root docker-entrypoint.sh /entrypoint.sh

USER dex
WORKDIR $DEXPATH

EXPOSE 5556

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dex", "serve", "/home/dex/config.yaml"]
