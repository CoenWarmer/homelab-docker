# Immich - Photo & Video Management

Self-hosted Google Photos alternative with mobile apps, AI-powered search, facial recognition, and automatic backup.

## Containers

| Container | Purpose |
|-----------|---------|
| immich-server | Main API and web interface |
| immich-ml | Machine learning (facial recognition, smart search, CLIP) |
| immich-redis | Caching and job queue |
| immich-postgres | Database with pgvector for vector search |

## Prerequisites

### 1. Environment Variables

Add to your root `.env` file:

```bash
# Immich
IMMICH_VERSION=release
IMMICH_DB_PASSWORD=<generate-a-strong-password>
IMMICH_API_KEY=<generate-after-first-login>
```

Generate the database password:
```bash
openssl rand -base64 32
```

### 2. Create Directories

```bash
# Photo library storage
sudo mkdir -p /tank/data/photos
sudo chown -R $USER:docker /tank/data/photos
sudo chmod -R 775 /tank/data/photos

# Config directories
mkdir -p /srv/docker/immich/{ml-cache,postgres,redis,profile}
```

### 3. Symlink .env

```bash
cd /opt/docker/homelab-docker/services/immich
ln -s ../../.env .env
```

## Usage

### Start the Service

```bash
cd /opt/docker/homelab-docker/services/immich
docker compose up -d
```

### First Login

1. Navigate to `https://photos.{your-domain}`
2. Create the first admin account
3. Generate an API key in Account Settings → API Keys (for Homepage widget)
4. Add the API key to `.env` as `IMMICH_API_KEY`

## Hardware Acceleration

This setup includes Intel Quick Sync support for the N100 processor:

- **Video transcoding**: Hardware-accelerated via `/dev/dri`
- **Machine Learning**: Can use OpenVINO for faster inference

To enable OpenVINO for ML (optional), uncomment the environment variables in `docker-compose.yml`:
```yaml
environment:
  MACHINE_LEARNING_WORKERS: 1
  MACHINE_LEARNING_WORKER_TIMEOUT: 120
```

And change the ML image to the OpenVINO variant:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-openvino
```

## Mobile Apps

Download the Immich mobile app:
- [iOS App Store](https://apps.apple.com/app/immich/id1613945587)
- [Google Play Store](https://play.google.com/store/apps/details?id=app.alextran.immich)
- [F-Droid](https://f-droid.org/packages/app.alextran.immich/)

### Authentication with Authelia

Since Authelia is in front of Immich, mobile app users will need to:
1. Log in via the web interface first (through Authelia)
2. The app should handle the OAuth flow automatically

If you experience issues with mobile app login, you may need to adjust Authelia's cookie settings or bypass Authelia for the `/api` endpoints.

## Backup

Important directories to back up:
- `/tank/data/photos` - All photos and videos
- `/srv/docker/immich/postgres` - Database (user data, metadata, faces, albums)

## Troubleshooting

### Check logs
```bash
docker logs immich-server
docker logs immich-ml
docker logs immich-postgres
```

### Verify hardware acceleration
```bash
docker exec immich-server ls -la /dev/dri
```

### Database issues
```bash
docker exec immich-postgres pg_isready -d immich -U immich
```

## Resources

- [Immich Documentation](https://immich.app/docs)
- [Immich GitHub](https://github.com/immich-app/immich)
- [Hardware Transcoding Guide](https://immich.app/docs/features/hardware-transcoding)






