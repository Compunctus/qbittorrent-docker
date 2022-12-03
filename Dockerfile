FROM ubuntu:kinetic

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG VERSION

ENV BITTORRENT_PORT=6881 \
    WEBUI_PORT=8080

USER root

# hadolint ignore=DL3008,DL3013,DL3015,SC2086
RUN \
  export EXTRA_INSTALL_ARG="binutils"; \
  apt-get -qq update \
  && \
  apt-get install -y \
    curl \
    geoip-bin \
    p7zip-full \
    python3 \
    unrar \
    unzip \
    ${EXTRA_INSTALL_ARG} \
  && \
  case "${TARGETPLATFORM}" in \
    'linux/amd64') export ARCH="x86_64" ;; \
    'linux/arm64') export ARCH="aarch64" ;; \
  esac \
  && useradd --shell /usr/bin/nologin --home-dir /config --create-home qbittorrent --uid 6000 \
  && usermod -p '*' qbittorrent \
  && mkdir /app \
  && curl -fsSL -o /app/qbittorrent-nox "https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/${ARCH}-qbittorrent-nox" \
  && chmod +x /app/qbittorrent-nox \
  && \
  apt-get remove -y ${EXTRA_INSTALL_ARG} \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && apt-get autoremove -y \
  && apt-get clean \
  && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/ \
  && chown -R qbittorrent:qbittorrent /app \
  && chmod -R u=rwX,go=rX /app \
  && chown -R qbittorrent:qbittorrent /config \
  && chmod -R u=rwX,go=rX /config \
  && printf "umask %d" "${UMASK}" >> /etc/bash.bashrc

USER qbittorrent

EXPOSE ${BITTORRENT_PORT} ${BITTORRENT_PORT}/udp ${WEBUI_PORT}

COPY ./shim/config.py /shim/config.py
COPY ./entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]

LABEL \
  org.opencontainers.image.title="qBittorrent" \
  org.opencontainers.image.source="https://github.com/qbittorrent/qBittorrent" \
  org.opencontainers.image.version="${VERSION}"
