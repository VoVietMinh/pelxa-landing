# Pelxa — Production Deployment Guide

Zero-downtime deployment to a single production server using Docker, nginx
and a blue/green pattern.

> Repo: https://github.com/VoVietMinh/pelxa-landing.git
> Stack: Node.js + Express + EJS + Tailwind, fronted by nginx in Docker.

---

## Architecture

```
                    ┌────────────────────────────┐
   internet  ──►──  │  nginx (host :80 / :443)   │
                    │  upstream pelxa_active     │ ← swapped on each deploy
                    └────────────┬───────────────┘
                                 │
                ┌────────────────┴───────────────┐
                ▼                                ▼
        ┌──────────────┐                ┌──────────────┐
        │  pelxa_blue  │   (only ONE    │  pelxa_green │
        │  Node:3000   │   serves at    │  Node:3000   │
        │  /healthz    │   any time)    │  /healthz    │
        └──────────────┘                └──────────────┘
```

Each deploy starts the standby color, waits for `/healthz` to go green,
atomically rewrites `deploy/nginx/active/upstream.conf` to point to the new
color, reloads nginx, and finally stops the old color. nginx's `reload` is
graceful — in-flight requests on the old workers are allowed to finish.

---

## 1. Server requirements (one-time)

- Ubuntu 22.04 LTS (or any modern Linux), 2+ vCPU, 2 GB RAM minimum
- Open ports: `22`, `80`, (`443` if using TLS)
- A non-root user with `sudo` and `docker` group membership

### Install Docker

```bash
# As root or with sudo
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
newgrp docker     # or log out/in
docker --version
docker compose version
```

---

## 2. First-time deploy (bootstrap)

```bash
# 1. Clone
cd /opt
sudo mkdir pelxa && sudo chown "$USER:$USER" pelxa
cd pelxa
git clone https://github.com/VoVietMinh/pelxa-landing.git .

# 2. Bootstrap — builds the image, starts nginx + pelxa_blue, verifies /healthz
chmod +x deploy/scripts/*.sh
./deploy/scripts/bootstrap.sh

# 3. Verify
curl -fsS http://127.0.0.1/healthz   # → {"status":"ok",...}
curl -fsS http://127.0.0.1/en | head -n 5
```

After bootstrap:
- `pelxa_blue` is the **active** color
- `pelxa_green` exists in compose but is **stopped** (profile-gated)
- Public traffic flows: client → nginx :80 → pelxa_blue:3000

---

## 3. Subsequent deploys (zero-downtime)

```bash
cd /opt/pelxa
./deploy/scripts/deploy.sh
```

What happens, in order:

| Step | Action | User-facing impact |
|------|--------|--------------------|
| 1 | `git pull origin main` | none |
| 2 | Detect current active color (blue or green) | none |
| 3 | `docker compose build` produces new `pelxa-app:latest` | none — build runs separately |
| 4 | Start the **standby** color container | none — not yet receiving traffic |
| 5 | Poll standby `/healthz` for up to 60 s | none |
| 6 | Atomically rewrite `active/upstream.conf` and `nginx -s reload` | **0 dropped requests** — nginx finishes in-flight requests on old workers, new requests go to new color |
| 7 | Stop + remove old color container | none |
| 8 | `docker image prune -f` | none |

If step 5 fails (new image is broken), the script aborts and the old color
keeps serving — no traffic is ever moved off a healthy container.

---

## 4. Rollback

If a bad deploy slips through health checks:

```bash
./deploy/scripts/rollback.sh
```

This brings the previous color back up using the existing image cached on
the host, swaps the upstream, and stops the bad one. ~5 seconds end-to-end.

> Note: rollback works because Docker keeps the previous `pelxa-app:latest`
> image layers on the host until they are pruned. To preserve named history
> across deploys, see "Tagging strategy" below.

---

## 5. CI / CD (optional)

If you want to push and have it auto-deploy, the simplest pattern is a
GitHub Actions workflow that SSHes into the server and runs the deploy
script. Skeleton:

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host:     ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key:      ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /opt/pelxa
            ./deploy/scripts/deploy.sh
```

Add the three secrets in **Settings → Secrets and variables → Actions**.

---

## 6. Domain + TLS via Cloudflare (Flexible SSL)

This is the recommended setup for `pelxa.com`. Cloudflare terminates TLS
for visitors; the origin only needs to serve plain HTTP on `:80`. No
certificates to install or renew on the server.

```
visitor ── HTTPS ──► Cloudflare ── HTTP ──► your server :80 ──► nginx ──► pelxa_blue
```

### 6.1 Add the domain to Cloudflare

1. **Cloudflare dashboard → Add a site** → enter `pelxa.com` → Free plan.
2. Copy the two Cloudflare nameservers Cloudflare assigns you.
3. Log into your domain registrar and replace the existing nameservers
   with the Cloudflare ones. Propagation usually completes in 5–60
   minutes.

### 6.2 DNS records

In Cloudflare → **DNS → Records**, create:

| Type | Name | Content              | Proxy status   | TTL  |
|------|------|----------------------|----------------|------|
| A    | `@`  | `<your.server.ip>`   | **Proxied** 🟧 | Auto |
| A    | `www`| `<your.server.ip>`   | **Proxied** 🟧 | Auto |

The orange cloud means traffic flows through Cloudflare's network — that's
what gives you the free TLS, caching, and DDoS shield.

### 6.3 SSL/TLS mode

Cloudflare → **SSL/TLS → Overview** → set encryption mode to
**Flexible**. (Visitor ↔ Cloudflare is HTTPS, Cloudflare ↔ origin is
HTTP — matches the `:80`-only origin we ship.)

Then under **SSL/TLS → Edge Certificates**, enable:

- **Always Use HTTPS** → On
- **Automatic HTTPS Rewrites** → On
- **Minimum TLS Version** → TLS 1.2

### 6.4 Origin firewall (recommended)

The origin should only accept traffic from Cloudflare — otherwise anyone
who knows your server IP can bypass Cloudflare. Lock down :80 with UFW:

```bash
# Allow SSH, deny direct :80, allow only Cloudflare's edge IPs
sudo ufw allow 22/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Cloudflare IPv4 ranges (https://www.cloudflare.com/ips/)
for cidr in \
  173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 \
  141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 \
  197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 \
  104.24.0.0/14 172.64.0.0/13 131.0.72.0/22; do
  sudo ufw allow from "$cidr" to any port 80 proto tcp
done

sudo ufw enable
sudo ufw status numbered
```

Now the only path to your nginx is via Cloudflare. Direct `curl
http://<server-ip>` from anywhere else will hang.

### 6.5 Real visitor IP in your logs

The nginx config in this repo already includes
`deploy/nginx/conf.d/00-cloudflare-realip.conf`, which lists Cloudflare's
edge ranges and tells nginx to read `CF-Connecting-IP`. Result: your
nginx access logs and the `X-Forwarded-For` header your Express app sees
contain the real visitor IP, not the Cloudflare edge node IP.

### 6.6 Recommended Cloudflare settings

| Setting | Where | Value |
|---------|-------|-------|
| Caching Level | Caching → Configuration | Standard |
| Browser Cache TTL | Caching → Configuration | Respect existing headers |
| Auto Minify | Speed → Optimization | (off — Tailwind already minified) |
| Brotli | Speed → Optimization | On |
| HTTP/3 (QUIC) | Network | On |
| Always Use HTTPS | SSL/TLS → Edge | On |
| HSTS | SSL/TLS → Edge | Enable, max-age 6mo |

### 6.7 Quick verification

After DNS propagates and the proxy is on:

```bash
# From your laptop
curl -I https://pelxa.com/
# → HTTP/2 200, Server: cloudflare, cf-ray: ...

curl -I https://www.pelxa.com/
# → HTTP/2 301, Location: https://pelxa.com/

# From the server, watch real visitor IPs appear in nginx logs
docker compose logs -f --tail=50 nginx
```

### 6.8 Upgrading later to Full (strict) SSL

Flexible SSL is the easiest setup but Cloudflare ↔ origin is still
HTTP. If/when you want end-to-end encryption, switch to **Full (strict)**:

1. Generate a Cloudflare **Origin Certificate** (15-year, free) under
   SSL/TLS → Origin Server → Create Certificate.
2. Save the cert + key on the server, mount them into the nginx
   container, add a `listen 443 ssl;` block, and bind container `:443`.
3. Switch the SSL/TLS mode to **Full (strict)**.

Until then, Flexible is perfectly fine — the public traffic is encrypted,
which is what end users see and what search engines care about.

---

## 7. Tagging strategy (optional, recommended)

Each deploy currently overwrites `pelxa-app:latest`. To keep an audit trail
and make rollbacks easier, tweak `deploy.sh` to also tag with the git SHA:

```bash
SHA="$(git rev-parse --short HEAD)"
docker tag pelxa-app:latest "pelxa-app:$SHA"
```

You can then roll back to any past commit with:

```bash
docker tag pelxa-app:<sha>   pelxa-app:latest
./deploy/scripts/rollback.sh
```

---

## 8. Common operations

```bash
# View live logs
docker compose logs -f --tail=200 nginx pelxa_blue pelxa_green

# Active color
grep "pelxa_" deploy/nginx/active/upstream.conf

# Force rebuild without deploy
docker compose build --no-cache pelxa_blue

# Stop everything
docker compose --profile blue --profile green down

# Health from inside the network
docker compose exec nginx wget -qO- http://pelxa_active/healthz
```

---

## 9. File map

```
.
├── Dockerfile                          # multi-stage build (build → runtime)
├── .dockerignore
├── docker-compose.yml                  # nginx + pelxa_blue + pelxa_green (profile)
└── deploy/
    ├── nginx/
    │   ├── nginx.conf                  # main nginx config
    │   ├── conf.d/pelxa.conf           # public server block
    │   └── active/upstream.conf        # active color — rewritten on deploy
    └── scripts/
        ├── bootstrap.sh                # first-time setup
        ├── deploy.sh                   # zero-downtime deploy
        └── rollback.sh                 # flip back to previous color
```

---

## 10. Why this is zero-downtime

Three guarantees combined:

1. **The new container is fully healthy before any traffic moves.**
   `deploy.sh` polls Docker's health status (which itself probes
   `/healthz`) and refuses to swap if the new container hasn't gone
   `healthy` within 60 seconds.
2. **The upstream swap is atomic.** Rewriting a single included file plus
   `nginx -s reload` is the standard nginx zero-downtime pattern — old
   workers keep serving in-flight requests until they finish; new
   requests go to fresh workers using the new upstream.
3. **The old container only stops AFTER nginx has reloaded** and a 5s
   drain window has elapsed, so any straggler requests on the old
   workers complete normally.

Net effect: no `502`, no dropped TCP connections, no truncated responses
during a deploy.
