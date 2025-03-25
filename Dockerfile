# Dockerfile for quick-postfix
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
    && rm -rf /var/lib/apt/lists/*


# Postfix configuration
RUN postconf -e "smtpd_sasl_local_domain = \$mydomain"
RUN postconf -e "mydomain = ${MYDOMAIN:-example.com}" && \
    postconf -e "myhostname = ${POSTFIX_HOSTNAME:-mail.example.com}"


RUN postconf -e 'smtpd_tls_cert_file=/etc/postfix/certs/fullchain.pem' && \
    postconf -e 'smtpd_tls_key_file=/etc/postfix/certs/privkey.pem' && \
    postconf -e 'smtpd_use_tls=yes' && \
    postconf -e 'smtpd_tls_auth_only=yes' && \
    postconf -e 'smtpd_sasl_auth_enable=yes' && \
    postconf -e 'smtpd_sasl_security_options=noanonymous' && \
    postconf -e 'smtpd_sasl_local_domain=' && \
    postconf -e 'broken_sasl_auth_clients=yes' && \
    postconf -e 'disable_vrfy_command=yes' && \
    postconf -e 'relayhost='

RUN postconf -M submission/inet="submission inet n - y - - smtpd" && \
    postconf -P "submission/inet/syslog_name=postfix/submission" && \
    postconf -P "submission/inet/smtpd_tls_security_level=encrypt" && \
    postconf -P "submission/inet/smtpd_sasl_auth_enable=yes" && \
    postconf -P "submission/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" && \
    postconf -M smtps/inet="smtps inet n - y - - smtpd" && \
    postconf -P "smtps/inet/syslog_name=postfix/smtps" && \
    postconf -P "smtps/inet/smtpd_tls_wrappermode=yes" && \
    postconf -P "smtps/inet/smtpd_sasl_auth_enable=yes" && \
    postconf -P "smtps/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" && \
    postconf -e "master_service_disable = smtp"


RUN echo "pwcheck_method: auxprop" > /etc/postfix/sasl/smtpd.conf && \
    echo "mech_list: PLAIN LOGIN" >> /etc/postfix/sasl/smtpd.conf

# Enable SASL authentication daemon
RUN sed -i 's/^START=.*/START=yes/' /etc/default/saslauthd

# Configure vim
RUN echo "set mouse-=a" >> /etc/vim/vimrc

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/etc/postfix/certs", "/var/spool/postfix"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["postfix", "start-fg"]
