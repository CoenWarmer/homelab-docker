## Included projects

- https://github.com/amir20/dozzle
- https://github.com/crazy-max/diun
- https://github.com/AnalogJ/scrutiny
- https://github.com/alexjustesen/speedtest-tracker
- https://github.com/louislam/uptime-kuma
- https://github.com/bbernhard/signal-cli-rest-api
- https://github.com/nicolargo/glances

## Dependencies

- Hard dependency on the **infra** service stack, which provides the Docker Socket Proxy
- You may which to provide some apps externally, especially Uptime Kuma. Public access via Reverse Proxy requires the **public** Service and Network

## Environment and Configuration

### Files
1. Copy `./configtemplates/scrutiny/scrutiny.yaml` to your config directory for Scrutiny `${CONFIGDIR}/scrutiny/scrutiny.yaml`

### Ports

- `PORT_SOCKY_PROXY` - defined as part of **infra**
- `PORT_DOZZLE`
- `PORT_SPEEDTEST`
- `PORT_UPKUMA`
- `PORT_SCRUTINY`
- `PORT_SCRUTINY_DB`
- `PORT_SIGNAL_API`
- `PORT_GLANCES`

### URLs
- `SERVER_URL` - universal. your internal url
- `DOMAIN` - universal. your public facing domain name

### Functionality
- `HOST_NAME` - Universal. Helps orient you within Dozzle
- `DIUN_NOTIF_DISCORD_WEBHOOKURL` - Refer to Diun's instructions. I use Discord
- `./staticconfig/diun/diun.yml` - Refer to Diun's instructions. You may need to edit this file for your needs.

- `SPEEDTEST_APP_KEY` - I don't really understand why this is needed, but it is. Nor why you have to run a container to be able to set its environment. Once the container is running, execute this command and paste the result into your .env: `php artisan key:generate --show`. Alternatively, visit https://speedtest-tracker.dev/ . More information here: https://github.com/alexjustesen/speedtest-tracker/releases/tag/v0.20.0
- `SPEEDTEST_SCHEDULE` - Provide a CRON expression. I don't understand why this was moved from the UI to environment variables...
- `SPEEDTEST_SERVERS` - Another confounding change. Rather than auto selection, you must again start the container first before setting its environment. Use `cd app/www && php artisan app:ookla-list-servers` within the Container's shell. Select some ids and concatenate them with comma: "1111,2222"

- `${CONFIGDIR}/scrutiny/scrutiny.yaml` - Refer to Scrutiny's instructions.


### Data and Backups
- `CONFIGDIR` - universal. where the containers store their configuration data (aka Volume)
- `DBDIR` - universal. where databases store their... databases. 
- Each harddisk should be shared to Scrutiny via `devices` (eg. /dev/sda)


## Signal API Setup

The Signal API provides a REST interface for sending Signal messages from other services (Radarr, Sonarr, etc.).

### First-time setup: Link to existing Signal account

1. Start the container: `docker compose up -d signal-api`
2. Generate a QR code to link as a secondary device:
   ```bash
   docker exec -it signal-api signal-cli link --name "homelab"
   ```
3. Scan the QR code with your Signal app (Settings → Linked Devices → Link New Device)
4. Test sending a message:
   ```bash
   curl -X POST "http://localhost:PORT_SIGNAL_API/v2/send" \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello from homelab!", "number": "+YOUR_SIGNAL_NUMBER", "recipients": ["+RECIPIENT_NUMBER"]}'
   ```

### Using with *arr apps

In Radarr/Sonarr → Settings → Connect → Webhook:
- **URL:** `http://signal-api:8080/v2/send`
- Configure payload to include message, number (sender), and recipients

### API Documentation

Visit `http://localhost:PORT_SIGNAL_API/v1/api` for the Swagger UI with all available endpoints.


## Backups
- If needed, standard backup of CONFIGDIR