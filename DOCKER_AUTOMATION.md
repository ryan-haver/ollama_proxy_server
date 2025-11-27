# Automated Docker Build & Deploy Setup

This repository is configured to automatically build and publish Docker images to GitHub Container Registry (GHCR) whenever the upstream repository (`ParisNeo/ollama_proxy_server`) is updated.

## 🔄 How It Works

### 1. **Upstream Sync Workflow** (`.github/workflows/sync-upstream.yml`)
- **Trigger**: Runs daily at 2 AM UTC (configurable via cron schedule)
- **Manual Trigger**: Can be triggered manually from the Actions tab
- **Process**:
  1. Checks for updates from the upstream repository
  2. If updates are found, merges them into the fork
  3. Triggers the Docker build workflow automatically

### 2. **Docker Build & Push Workflow** (`.github/workflows/docker-build-push.yml`)
- **Triggers**:
  - Automatically when upstream sync detects changes
  - When code changes are pushed to `main` branch
  - Manual trigger from the Actions tab
- **Process**:
  1. Builds multi-platform Docker image (amd64 & arm64)
  2. Pushes to GitHub Container Registry (GHCR)
  3. Tags images with `latest`, branch name, and commit SHA

## 📦 Using the Docker Image

### Pull the Image
```bash
docker pull ghcr.io/ryan-haver/ollama_proxy_server:latest
```

### Environment Variables

#### **Required (Change These!)**
- `ADMIN_PASSWORD` - Admin password (default: `changeme` - **CHANGE THIS!**)
- `SECRET_KEY` - Session encryption key (default provided - **CHANGE THIS for production!**)

#### **Optional (with sensible defaults)**
- `DATABASE_URL` - Database connection (default: `sqlite+aiosqlite:///./ollama_proxy.db`)
- `ADMIN_USER` - Admin username (default: `admin`)
- `PROXY_PORT` - Server port (default: `8080`)
- `LOG_LEVEL` - Logging verbosity (default: `info`, options: `debug`, `info`, `warning`, `error`, `critical`)

### Quick Start (Minimal)
```bash
docker run -d \
  -p 8080:8080 \
  -e ADMIN_PASSWORD="your-secure-password" \
  -e SECRET_KEY="$(openssl rand -hex 32)" \
  -v ollama_proxy_data:/home/app \
  ghcr.io/ryan-haver/ollama_proxy_server:latest
```

### Production Setup (Recommended)
```bash
docker run -d \
  --name ollama-proxy \
  -p 8080:8080 \
  -e ADMIN_USER="admin" \
  -e ADMIN_PASSWORD="your-secure-password" \
  -e SECRET_KEY="your-generated-secret-key" \
  -e LOG_LEVEL="info" \
  -v ollama_proxy_data:/home/app \
  --restart unless-stopped \
  ghcr.io/ryan-haver/ollama_proxy_server:latest
```

### With Custom Database (PostgreSQL)
```bash
docker run -d \
  --name ollama-proxy \
  -p 8080:8080 \
  -e DATABASE_URL="postgresql+asyncpg://user:password@postgres:5432/ollama_proxy" \
  -e ADMIN_PASSWORD="your-secure-password" \
  -e SECRET_KEY="your-generated-secret-key" \
  --restart unless-stopped \
  ghcr.io/ryan-haver/ollama_proxy_server:latest
```

### Run the Container
```bash
docker run -d \
  --name ollama-proxy \
  -p 8080:8080 \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=yourpassword \
  ghcr.io/ryan-haver/ollama_proxy_server:latest
```

### With Docker Compose
```yaml
version: '3.8'
services:
  ollama-proxy:
    image: ghcr.io/ryan-haver/ollama_proxy_server:latest
    ports:
      - "8080:8080"
    environment:
      - ADMIN_USER=admin
      - ADMIN_PASSWORD=your-secure-password
      - SECRET_KEY=your-generated-secret-key
      - LOG_LEVEL=info
      - DATABASE_URL=sqlite+aiosqlite:///./ollama_proxy.db
    volumes:
      - ollama_proxy_data:/home/app  # Container working directory where database is stored
    restart: unless-stopped

volumes:
  ollama_proxy_data:
```

### Unraid Deployment

For Unraid, specify PUID/PGID to match your user permissions:

```bash
docker run -d \
  --name ollama-proxy \
  -p 8080:8080 \
  -e PUID=99 \
  -e PGID=100 \
  -e ADMIN_PASSWORD="your-secure-password" \
  -e SECRET_KEY="your-generated-secret-key" \
  -v /mnt/user/appdata/ollama-proxy:/home/app \
  --restart unless-stopped \
  ghcr.io/ryan-haver/ollama_proxy_server:latest
```

**Unraid Default Values:**
- PUID: `99` (nobody user)
- PGID: `100` (users group)

**Finding Your PUID/PGID:**
```bash
# SSH into Unraid and run:
id <username>
```

## 🔐 Security Best Practices

### Generate a Secure SECRET_KEY
```bash
# Using Python
python -c "import secrets; print(secrets.token_hex(32))"

# Using OpenSSL
openssl rand -hex 32

# Using PowerShell
-join ((48..57) + (65..70) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

### Use Strong ADMIN_PASSWORD

- At least 12 characters
- Mix of uppercase, lowercase, numbers, and symbols
- Never use default passwords in production

### Data Persistence

- **SQLite (default)**: Mount `/home/app` volume to persist the database
  - Container working directory: `/home/app`
  - Database file location: `/home/app/ollama_proxy.db`
  - Example: `-v ollama_proxy_data:/home/app`
- **PostgreSQL (recommended for production)**: Use external database with `DATABASE_URL`
- Always use named volumes or bind mounts for data persistence

## ⚙️ Configuration

### Required Permissions
The workflows require the following permissions (already configured):
- **Contents**: write (for syncing upstream changes)
- **Packages**: write (for pushing to GHCR)

These permissions are automatically granted via `GITHUB_TOKEN` - no additional secrets needed!

### Customizing Sync Schedule
Edit `.github/workflows/sync-upstream.yml` and modify the cron schedule:
```yaml
schedule:
  - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

## 🚀 Manual Triggers

### Sync Fork Manually
1. Go to **Actions** tab
2. Select **Sync Fork with Upstream**
3. Click **Run workflow**

### Build Docker Image Manually
1. Go to **Actions** tab
2. Select **Build and Push Docker Image**
3. Click **Run workflow**

## 📊 Monitoring

- Check the **Actions** tab to see workflow runs
- Each successful Docker build will show:
  - Build summary with image tags
  - Pull command for the new image
  - Multi-platform build confirmation

## 🔍 Troubleshooting

### Workflow Fails
- Check the Actions logs for detailed error messages
- Verify repository permissions are enabled (Settings → Actions → General)

### Can't Pull Image
- Ensure the package is public: Repository → Packages → Package Settings → Change visibility
- Or authenticate with GHCR:
  ```bash
  echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
  ```

## 📝 Image Tags

Images are tagged with:
- `latest` - Most recent build from main branch
- `main-<sha>` - Specific commit SHA
- `main` - Latest from main branch

## 🔗 Links

- **Upstream Repository**: https://github.com/ParisNeo/ollama_proxy_server
- **This Fork**: https://github.com/ryan-haver/ollama_proxy_server
- **GHCR Package**: https://github.com/ryan-haver/ollama_proxy_server/pkgs/container/ollama_proxy_server
