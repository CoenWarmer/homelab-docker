# Home Assistant

Home automation platform for controlling and monitoring smart home devices.

## Services

- **Home Assistant** - Open source home automation platform

## Configuration

### Environment Variables Required

Add these to your `.env` file:

```bash
# Home Assistant
PORT_HOMEASSISTANT=8123
HOMEPAGE_HOMEASSISTANT_API=your_long_lived_access_token_here
```

### Getting the API Token

1. Start Home Assistant and complete initial setup
2. Navigate to your profile (click on your name in the sidebar)
3. Scroll down to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Give it a name (e.g., "Homepage Dashboard")
6. Copy the token and add it to your `.env` file

### Network Mode

By default, this configuration uses bridge networking with port mapping. This works for most use cases.

If you need device discovery (e.g., for Chromecast, DLNA, mDNS), you can switch to host network mode:

1. Uncomment the `network_mode: host` line in `docker-compose.yml`
2. Comment out or remove the `networks:` and `ports:` sections

**Note:** Host network mode gives the container direct access to the host's network interface.

### USB Device Access

If you're using USB dongles for Zigbee, Z-Wave, or other protocols:

1. Find your device path:
   ```bash
   ls -l /dev/tty*
   ```

2. Uncomment the appropriate device lines in `docker-compose.yml` and update the paths:
   ```yaml
   devices:
     - /dev/ttyUSB0:/dev/ttyUSB0  # Update with your device path
   ```

3. You may need to add your user to the `dialout` group:
   ```bash
   sudo usermod -a -G dialout $USER
   ```

## Usage

### Starting the Service

```bash
cd /opt/docker/homelab-docker/services/home-assistant
docker compose up -d
```

### Accessing Home Assistant

- Web Interface: `http://your-server-ip:8123`

### First-Time Setup

1. Navigate to the web interface
2. Create your admin account
3. Configure your location and units
4. Start adding integrations for your devices

## Backup

Home Assistant configuration is stored in `${CONFIGDIR}/homeassistant` (typically `/srv/docker/homeassistant`).

Important files to backup:
- `configuration.yaml` - Main configuration
- `automations.yaml` - Your automations
- `scripts.yaml` - Custom scripts
- `secrets.yaml` - Sensitive data (passwords, tokens)
- `.storage/` - Contains entities, areas, and UI configuration

## Reverse Proxy Setup

To expose Home Assistant through Caddy, add this to your `Caddyfile`:

```
ha.${DOMAIN} {
  import headers
  import main

  reverse_proxy homeassistant:8123
}
```

Then update your Home Assistant `configuration.yaml`:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.0.0.0/8  # Adjust based on your Docker network
```

## Resources

- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Integration List](https://www.home-assistant.io/integrations/)
- [Community Forum](https://community.home-assistant.io/)












