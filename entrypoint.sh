#!/bin/bash

source /.env

# Certificados SSL/TLS
CERT_DIR="/etc/postfix/certs"
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/CN=${POSTFIX_HOSTNAME:-mail.local}" \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem"
fi

# REMOVE DEFINITIVAMENTE O BANCO SASLDB2
rm -f /etc/sasldb2*

# Recria usuários agora com domínio correto!
IFS=',' read -ra USERS <<< "$USER_LIST"
for userpass in "${USERS[@]}"; do
    IFS=':' read user pass <<< "$userpass"
    echo "$pass" | saslpasswd2 -p -c -u "$MYDOMAIN" "$user"
done
chown postfix:sasl /etc/sasldb2
chmod 640 /etc/sasldb2

# Configuração básica obrigatória
postconf -e "myhostname = ${POSTFIX_HOSTNAME}"
postconf -e "mydomain = ${MYDOMAIN}"
postconf -e "smtpd_sasl_local_domain = ${MYDOMAIN}"
postconf -e "maillog_file = /dev/stdout"

# Relay (se aplicável)
if [ "$QUICKPOSTFIX_MODE" = "relay" ]; then
    postconf -e "relayhost = [$RELAY_HOST]:$RELAY_PORT"
    echo "[$RELAY_HOST]:$RELAY_PORT $RELAY_USER:$RELAY_PASSWORD" > /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_sasl_security_options = noanonymous"
    postconf -e "smtp_tls_security_level = encrypt"
else
    postconf -e "relayhost ="
fi
# Iniciar postfix em foreground
exec postfix start-fg
