# quick-postfix-relay

quick-postfix-relay is a simple service designed to allow IoT devices, scripts, or other equipment to authenticate and send emails in general. It also supports defining a smarthost for relaying emails, such as Gmail or other email services.

## Features

- **Simple Authentication:** Easily configure user authentication for sending emails.
- **Relay Support:** Define a smarthost for relaying emails.
- **Flexible Configuration:** Customize settings via environment variables.

## How to Run

You have two options to run Quick Postfix with Docker:

### 1. Using `docker run`

You can run the container with a single Docker command that includes all required environment variables. For example:

```bash
docker run \
  --env QUICKPOSTFIX_MODE=relay \
  --env USER_LIST="user1:password,user2:password" \
  --env POSTFIX_HOSTNAME=mail.example.com \
  --env MYDOMAIN=example.com \
  --env RELAY_HOST=smtp.relay.com \
  --env RELAY_PORT=587 \
  --env RELAY_USER=relayuser \
  --env RELAY_PASSWORD=relaypassword \
  -p 465:465 \
  -p 587:587 \
  -v postfix-certs:/etc/postfix/certs \
  eduardosilva/quick-postfix-relay:latest
```

### 2. Using Docker Compose and .env file

1. **Download the `docker-compose.yml` file.**
2. **Create a `.env` file** using the provided `.env.example` as a template.
3. **Run the following command:**

   ```bash
   docker-compose up
   ```

## Configuration Variables

The service can be configured with the following environment variables:

- **QUICKPOSTFIX_MODE:** Mode of operation. Set to either `standalone` or `relay`.
- **USER_LIST:** A comma-separated list of users in the format `user1:password,user2:password`.
- **POSTFIX_HOSTNAME:** Hostname for Postfix (required in standalone mode).
- **MYDOMAIN:** Domain name for Postfix (required in standalone mode).
- **RELAY_HOST:** SMTP relay host (required in relay mode).
- **RELAY_PORT:** SMTP relay port (required in relay mode).
- **RELAY_USER:** SMTP relay username (required in relay mode).
- **RELAY_PASSWORD:** SMTP relay password (required in relay mode).
- **SSL_PORT:** External port mapping for SSL submission (defaults to `465` if using Docker Compose).
- **TLS_PORT:** External port mapping for TLS submission (defaults to `587` if using Docker Compose).
- **TZ:** Timezone for the container (optional).


## Additional Note for Standalone Mode

If you run quick-postfix-relay in standalone mode, keep in mind that additional configurations are required for proper email delivery. These include, but are not limited to:

- DNS Configuration
- Reverse DNS Setup
- SPF (Sender Policy Framework)
- DKIM (DomainKeys Identified Mail)

Ensure these settings are correctly configured to avoid issues with email deliverability and to improve your server's reputation.