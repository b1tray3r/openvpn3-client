FROM debian:11 AS base

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=0.9

LABEL eu.dbergloev.build-date=$BUILD_DATE \
      eu.dbergloev.vcs-url="https://github.com/b1tray3r/openvpn3-client.git" \
      eu.dbergloev.schema-version=$VERSION

VOLUME [ "/app" ]

ENV TZ=Europe/Berlin \
    PUID=1000 \
    PGID=1000 \
    VPN_DNS="1.1.1.1,1.0.0.1"

RUN apt-get -y update && apt-get -y dist-upgrade \
        && apt-get install -y tini iptables curl dnsutils net-tools iproute2 iputils-ping gnupg lsb-release procps oathtool \
        && curl -fsSL https://swupdate.openvpn.net/repos/openvpn-repo-pkg-key.pub | gpg --dearmor | tee /etc/apt/trusted.gpg.d/openvpn-repo-pkg-keyring.gpg >/dev/null \
        && curl -fsSL https://swupdate.openvpn.net/community/openvpn3/repos/openvpn3-$(lsb_release -c | awk '{print $2}').list -o /etc/apt/sources.list.d/openvpn3.list \
        && apt-get -y update && apt-get install -y openvpn3 \
        && addgroup --system docker_group  && adduser --system --home /app docker_user && usermod -g docker_group docker_user \
        && apt-get purge -y lsb-release && apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD init /opt/init/
RUN chmod +x /opt/init/run.sh /opt/init/vpn-connect.sh /opt/init/vpn-disconnect.sh

FROM base AS openvpn3

ENV OVPN="/app/config.ovpn"

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/init/run.sh"]
