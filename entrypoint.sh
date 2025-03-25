#!/bin/bash
set -e

# Create SSL certificate if it doesn't exist
CERT_DIR="/etc/postfix/certs"
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/CN=${POSTFIX_HOSTNAME:-mail.example.com}" \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem"
fi

rm -f /etc/sasldb2*

# Create user list
IFS=',' read -ra USERS <<< "$USER_LIST"
for userpass in "${USERS[@]}"; do
    IFS=':' read user pass <<< "$userpass"
    # Acrescenta o domínio se não houver '@'
    if [[ "$user" != *"@"* ]]; then
        user="${user}@${MYDOMAIN}"
    fi
    echo "$pass" | saslpasswd2 -p -c -u "$MYDOMAIN" "$user"
done

chown postfix:postfix /etc/sasldb2
chmod 660 /etc/sasldb2

# Enable submission (port 587) with TLS and authentication
postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
postconf -P "submission/inet/syslog_name=postfix/submission"
postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"

# Enable smtps (port 465) with TLS and authentication
postconf -M smtps/inet="smtps   inet   n   -   y   -   -   smtpd"
postconf -P "smtps/inet/syslog_name=postfix/smtps"
postconf -P "smtps/inet/smtpd_tls_wrappermode=yes"
postconf -P "smtps/inet/smtpd_sasl_auth_enable=yes"
postconf -P "smtps/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"

postconf -e "maillog_file = /dev/stdout"

# Configure relay host
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

if [ -d /var/spool/postfix ]; then
    mkdir -p /var/spool/postfix/etc
    cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
fi

exec postfix start-fg
