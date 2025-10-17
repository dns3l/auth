FROM dexidp/dex:v2.44.0-alpine@sha256:5d0656fce7d453c0e3b2706abf40c0d0ce5b371fb0b73b3cf714d05f35fa5f86

LABEL org.opencontainers.image.title="dns3l auth"
LABEL org.opencontainers.image.description="An OIDC provider for DNS3L"
LABEL org.opencontainers.image.version=0.0.0-semantically-released

ENV VERSION=0.0.0-semantically-released

# provided via BuildKit
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# defaults for none BuildKit
ARG _platform=${TARGETPLATFORM:-linux/amd64}
ARG _os=${TARGETOS:-linux}
ARG _arch=${TARGETARCH:-amd64}
ARG _variant=${TARGETVARIANT:-}

ENV DEXPATH="/home/dex"
ENV DEX_FRONTEND_DIR="/srv/dex/web"
ENV DEX="/srv/dex"

ARG DEXUID=10042
ARG DEXGID=10042

USER root
RUN apk --update upgrade && \
    apk add --no-cache tini bash coreutils tzdata openssl ca-certificates curl busybox-extras \
        apache2-utils uuidgen && \
    addgroup -g ${DEXGID} dex && \
    adduser -D -u ${DEXUID} -G dex dex && \
    chmod g-s ${DEXPATH} && \
    chown dex:dex ${DEXPATH} && \
    rm -rf /var/cache/apk/*

# Install dockerize
# https://github.com/powerman/dockerize doesn't enabled SHA digests for assets via GitHub API
#
ARG DCKRZ_LINUX_AMD64_SHA256=9239915df1cc59b4ad3927f9aad6a36ffc256d459cff9b073ae9d7f9c9149a03
ARG DCKRZ_LINUX_ARM64_SHA256=3a11c2f207151c304e8cf7aef060cf30ce8d56979b346329087f3a2c6b6055cb
ENV DCKRZ_VERSION="0.24.0"
RUN curl -fsSL https://github.com/powerman/dockerize/releases/download/v${DCKRZ_VERSION}/dockerize-v${DCKRZ_VERSION}-${_os}-${_arch}${_variant} > /dckrz && \
    chmod a+x /dckrz && \
    echo "${DCKRZ_LINUX_AMD64_SHA256} */dckrz" >> /dckrz.sha256 && \
    echo "${DCKRZ_LINUX_ARM64_SHA256} */dckrz" >> /dckrz.sha256 && \
    sha256sum -c /dckrz.sha256 2>/dev/null | grep 'OK$'

COPY --chown=dex:dex web/ ${DEXPATH}
COPY --chown=root:root config.docker.yaml /etc/dex/config.yaml.tmpl
COPY --chown=root:root docker-entrypoint.sh /entrypoint.sh

USER dex
WORKDIR $DEXPATH

EXPOSE 5556

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dex", "serve", "/home/dex/config.yaml"]
