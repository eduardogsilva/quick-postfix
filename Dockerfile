# Dockerfile for quick-postfix using sasldb (auxprop) with submission and smtps enabled
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    postfix \
    sasl2-bin \
    libsasl2-modules \
    openssl \
    net-tools \
    telnet \
    swaks \
    vim-nox \
    procps \
    syslog-ng \
    && rm -rf /var/lib/apt/lists/*

# SASL configuration
RUN mkdir -p /etc/postfix/sasl && \
    cat > /etc/postfix/sasl/smtpd.conf <<'EOF'
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF

# Postfix configuration
RUN postconf -e "myhostname = ${POSTFIX_HOSTNAME:-mail.example.com}" && \
    postconf -e "mydomain = ${MYDOMAIN:-example.com}" && \
    postconf -e "smtpd_sasl_auth_enable = yes" && \
    postconf -e "broken_sasl_auth_clients = no" && \
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated,reject_unauth_destination" && \
    postconf -e "smtpd_tls_cert_file = /etc/postfix/certs/fullchain.pem" && \
    postconf -e "smtpd_tls_key_file = /etc/postfix/certs/privkey.pem" && \
    postconf -e "smtpd_use_tls = yes" && \
    postconf -e "smtpd_tls_auth_only = yes" && \
    postconf -e "relayhost ="

EXPOSE 465 587

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["postfix", "start-fg"]
