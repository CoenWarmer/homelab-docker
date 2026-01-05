# iCloud Photos Downloader

Downloads photos and videos from iCloud to your server. Works great with Immich as an external library.

## How It Works

- Syncs photos from iCloud every 24 hours
- Organizes into `Year/Month` folder structure
- Downloads original quality photos and videos
- Stores in `/tank/data/photos/icloud` for Immich to access

## Prerequisites

### 1. Environment Variables

Add to your root `.env` file:

```bash
# iCloud Photos Downloader
ICLOUD_APPLE_ID=your-apple-id@email.com
```

### 2. Create Directories

```bash
# Photo download location
sudo mkdir -p /tank/data/photos/icloud
sudo chown -R $USER:docker /tank/data/photos/icloud

# Config directory for auth cookies
mkdir -p /srv/docker/icloudpd
```

### 3. Symlink .env

```bash
cd /home/coenw/Dev/homelab-docker/services/icloudpd
ln -s ../../.env .env
```

## Initial Setup (2FA Authentication)

iCloud requires two-factor authentication. You must complete this interactively:

### Step 1: Start the container

```bash
cd /home/coenw/Dev/homelab-docker/services/icloudpd
docker compose up -d
```

### Step 2: Run initial authentication

```bash
docker exec -it icloudpd icloudpd --username your-apple-id@email.com --directory /data --password
```

You'll be prompted for:
1. Your iCloud password
2. A 2FA code sent to your trusted device

### Step 3: Verify authentication worked

```bash
docker logs icloudpd
```

The container will now sync automatically every 24 hours.

## Re-Authentication

Apple's 2FA cookies expire periodically (typically every 2-3 months). When this happens:

1. You'll see authentication errors in the logs
2. Run the authentication command again:

```bash
docker exec -it icloudpd icloudpd --username your-apple-id@email.com --directory /data --password
```

## Integrating with Immich

To have Immich display your iCloud photos:

1. Go to Immich → Administration → External Libraries
2. Click "Create Library"
3. Add import path: `/usr/src/app/upload/icloud`
4. Set up a scan schedule (or scan manually)

**Note**: You'll need to add this mount to Immich's docker-compose:

```yaml
volumes:
  - /tank/data/photos/icloud:/usr/src/app/upload/icloud:ro
```

## Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNCHRONISATION_INTERVAL` | 86400 | Sync frequency in seconds (24h) |
| `PHOTO_SIZE` | original | Photo quality: original, medium, thumb |
| `FOLDER_STRUCTURE` | {:%Y/%m} | Folder organization pattern |
| `AUTO_DELETE` | false | Delete local files removed from iCloud |
| `SKIP_VIDEOS` | false | Skip video downloads |
| `RECENT_ONLY` | (unset) | Only download N most recent photos |

## Manual Sync

To trigger a sync manually:

```bash
docker exec icloudpd icloudpd --username your-apple-id@email.com --directory /data
```

## Troubleshooting

### Check logs
```bash
docker logs icloudpd -f
```

### Authentication issues
```bash
# Clear cookies and re-authenticate
docker exec icloudpd rm -rf /config/cookies
docker exec -it icloudpd icloudpd --username your-apple-id@email.com --directory /data --password
```

### Check downloaded files
```bash
ls -la /tank/data/photos/icloud
```

## Resources

- [icloudpd GitHub](https://github.com/icloud-photos-downloader/icloud_photos_downloader)
- [icloudpd Docker Hub](https://hub.docker.com/r/icloudpd/icloudpd)






