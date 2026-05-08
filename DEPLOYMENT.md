# Pelxa — Production Deployment Guide

Zero-downtime deployment using **host nginx** as a reverse proxy in front
of a **dockerized Node.js app** running blue/green on `127.0.0.1:5001` /
`127.0.0.1:5002`. Domain `pelxa.com` is fronted by Cloudflare in
**Flexible** SSL mode.

> Repo: https://github.com/VoVietMinh/pelxa-landing.git

---

## Architecture

```
                      ┌─────────────────────────┐
   visitor ──HTTPS──► │   Cloudflare (proxied)  │
                      └────────────┬────────────┘
                                   │  HTTP (Flexible mode)
                                   ▼
                       ┌──────────────────────┐
                       │  HOST nginx :80      │  ← apt install nginx
                       │  upstream pelxa_active │ ← swapped on each deploy
                       └─────────┬────────────┘
                                 │
                  ┌──────────────┴──────────────┐
                  ▼ (default = blue)           ▼ (only one runs at a time)
        ┌───────────────────┐         ┌───────────────────┐
        │ pelxa_blue        │         │ pelxa_green       │
        │ 127.0.0.1:5001 → │         │ 127.0.0.1:5002 → │
        │ container :3000   │         │ container :3000   │
        │ /healthz          │         │ /healthz          │
        └───────────────────┘         └───────────────────┘
```

### Why this layout

- **App ports bind to `127.0.0.1` only** — neither 5001 nor 5002 is reachable
  from the public internet. Only host nginx (running locally) can connect
  to them. No firewall rule needed for those ports.
- **Host nginx**, not containerized — easier to manage, supports certbot
  natively, can serve multiple sites on the same box later.
- **Blue / green ports** — at any moment only one color is up. The deploy
  script starts the other color, waits for it healthy, swaps the upstream
  in nginx, reloads nginx gracefully, then stops the old color.

---

## 1. Server prerequisites (one-time)

- Ubuntu 22.04 LTS or newer
- Open ports inbound: `22` (SSH), `80` (HTTP — only Cloudflare needs it)
- Docker + docker compose v2

```bash
# As root or sudo
curl -fsSL https://get.docker.com | sh
docker --version
docker compose version
```

---

## 2. First-time deploy (bootstrap)

Run on the production server, as root (or with sudo).

```bash
cd /opt
mkdir -p pelxa
cd pelxa
git clone https://github.com/VoVietMinh/pelxa-landing.git .

chmod +x deploy/scripts/*.sh
./deploy/scripts/bootstrap.sh
```

`bootstrap.sh` will:

1. `apt-get install nginx` (if not present)
2. Copy these files into `/etc/nginx/conf.d/`:
   - `00-cloudflare-realip.conf` — restore real visitor IP from `CF-Connecting-IP`
   - `01-pelxa-upstream.conf` — active upstream (initial: `127.0.0.1:5001`)
   - `10-pelxa.conf` — server blocks for `pelxa.com` + `www.pelxa.com`
3. Disable Ubuntu's default `/etc/nginx/sites-enabled/default`
4. `nginx -t` + `systemctl reload nginx`
5. `docker compose build pelxa_blue` and `docker compose up -d pelxa_blue`
6. Poll Docker healthcheck until `pelxa_blue` is `healthy`
7. `curl http://127.0.0.1/healthz` → `{"status":"ok",...}`

After this:

```bash
docker compose ps        # pelxa_blue Up (healthy), no nginx container
ss -tlnp | grep -E '(:80|:5001)'  # nginx on :80 (host), pelxa_blue on 127.0.0.1:5001
curl -fsS http://127.0.0.1/healthz
curl -fsS http://127.0.0.1/en | head -5
```

---

## 3. Subsequent deploys (zero-downtime)

```bash
cd /opt/pelxa
./deploy/scripts/deploy.sh
```

Step by step (also resyncs static nginx configs in case they changed):

| Step | Action | User-facing impact |
|------|--------|--------------------|
| 1 | `git pull origin main` | none |
| 2 | Resync `00-cloudflare-realip.conf` and `10-pelxa.conf` to `/etc/nginx/conf.d/` | none |
| 3 | Detect active port (5001=blue, 5002=green) | none |
| 4 | `docker compose build` produces new `pelxa-app:latest` | none — build runs separately |
| 5 | Start the **standby** color on the OTHER port | none — not yet receiving traffic |
| 6 | Poll standby `/healthz` for up to 60 s | none |
| 7 | Atomically rewrite `01-pelxa-upstream.conf` to point to new port | none |
| 8 | `nginx -t` + `nginx -s reload` (graceful) | **0 dropped requests** — old workers finish in-flight requests |
| 9 | Stop + remove old color container | none |
| 10 | `docker image prune -f` | none |

If step 6 fails (new image is broken), the script aborts and the old color
keeps serving — no traffic is ever moved off a healthy container.

---

## 4. Rollback

```bash
./deploy/scripts/rollback.sh
```

Brings the previous color back up using the existing image cached on the
host, swaps the upstream, stops the bad one. ~5 seconds end-to-end.

---

## 5. Domain + Cloudflare (Flexible SSL)

This is the recommended setup for `pelxa.com`. Cloudflare terminates TLS
for visitors; the origin only needs HTTP on `:80`. No certs to manage on
the server.

### 5.1 Add the domain to Cloudflare

1. Cloudflare dashboard → **Add a site** → enter `pelxa.com` → Free plan.
2. Copy the two Cloudflare nameservers Cloudflare assigns.
3. At your domain registrar, replace existing nameservers with the
   Cloudflare ones. Propagation: 5–60 minutes.

### 5.2 DNS records

In Cloudflare → **DNS → Records**:

| Type | Name | Content              | Proxy status   | TTL  |
|------|------|----------------------|----------------|------|
| A    | `@`  | `<your.server.ip>`   | **Proxied** 🟧 | Auto |
| A    | `www`| `<your.server.ip>`   | **Proxied** 🟧 | Auto |

The orange cloud is required — that's what gives you free TLS, caching,
and DDoS shield, AND lets the origin stay on plain HTTP `:80`.

### 5.3 SSL/TLS settings

Cloudflare → **SSL/TLS → Overview** → set encryption mode = **Flexible**.

Then **SSL/TLS → Edge Certificates**:

- **Always Use HTTPS** = On
- **Automatic HTTPS Rewrites** = On
- **Minimum TLS Version** = TLS 1.2

### 5.4 Test before locking down

Get the server IP:

```bash
curl -fsS https://api.ipify.org && echo
```

From the server you can fake-resolve `pelxa.com` to your origin IP without
waiting for DNS, to confirm nginx is ready:

```bash
IP=$(curl -fsS https://api.ipify.org)

curl -I --resolve pelxa.com:80:$IP     http://pelxa.com/en
# → HTTP/1.1 200

curl -I --resolve www.pelxa.com:80:$IP http://www.pelxa.com/
# → HTTP/1.1 301 Location: https://pelxa.com/

curl -fsS --resolve pelxa.com:80:$IP   http://pelxa.com/en \
     | grep -oE "<title>[^<]+</title>"
# → <title>Pelxa — Content, Ads & Traffic Solutions for Global Partners</title>
```

After Cloudflare DNS lands, from your laptop:

```bash
dig +short pelxa.com         # → Cloudflare IPs (104.x or 172.x)
curl -I https://pelxa.com/   # → HTTP/2 200, server: cloudflare
curl -I https://www.pelxa.com/   # → HTTP/2 301
```

### 5.5 Lock origin to Cloudflare only (recommended, AFTER 5.4 passes)

⚠️ Do NOT run this until `https://pelxa.com/` is confirmed live —
otherwise you can lock yourself out of `:80` while the proxy isn't ready.

```bash
apt-get install -y ufw

ufw allow 22/tcp
ufw default deny incoming
ufw default allow outgoing

# Cloudflare IPv4 ranges (https://www.cloudflare.com/ips/)
for cidr in \
  173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 \
  141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 \
  197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 \
  104.24.0.0/14 172.64.0.0/13 131.0.72.0/22; do
  ufw allow from "$cidr" to any port 80 proto tcp
done

ufw --force enable
ufw status numbered
```

After this, `curl http://<server-ip>/` from any non-Cloudflare network
will hang. Site still works through `https://pelxa.com/`.

### 5.6 Verify Cloudflare real-IP is working

After traffic flows through Cloudflare:

```bash
sudo tail -f /var/log/nginx/access.log
```

The first column should show real visitor IPs (Vietnam mobile, US
desktop, etc.) — not `104.x` Cloudflare edge IPs. That's the
`00-cloudflare-realip.conf` doing its job.

---

## 6. Common operations

```bash
# Live logs
sudo tail -f /var/log/nginx/access.log
docker compose logs -f --tail=200 pelxa_blue
# (or pelxa_green if that's currently active)

# Active color / port
grep "127\.0\.0\.1" /etc/nginx/conf.d/01-pelxa-upstream.conf

# nginx config sanity
sudo nginx -t

# Force-rebuild without deploying
docker compose build --no-cache pelxa_blue

# Stop everything app-side (nginx keeps running, will return 502 until you restart blue)
docker compose --profile blue --profile green down

# Restart just the active app
docker compose restart pelxa_blue
```

---

## 7. CI / CD (optional)

GitHub Actions skeleton — pushes to `main` trigger a deploy:

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

Add `PROD_HOST`, `PROD_USER`, `PROD_SSH_KEY` in **repo Settings → Secrets
and variables → Actions**.

---

## 8. File map

```
.
├── Dockerfile                          # multi-stage build
├── .dockerignore
├── docker-compose.yml                  # pelxa_blue (active) + pelxa_green (profile)
└── deploy/
    ├── nginx-host/                     # configs that get installed on the host
    │   ├── 00-cloudflare-realip.conf   # → /etc/nginx/conf.d/
    │   ├── 01-pelxa-upstream.conf      # → /etc/nginx/conf.d/  (rewritten on deploy)
    │   └── 10-pelxa.conf               # → /etc/nginx/conf.d/
    └── scripts/
        ├── bootstrap.sh                # one-time setup (installs nginx, starts blue)
        ├── deploy.sh                   # zero-downtime deploy (build + flip)
        └── rollback.sh                 # flip back to previous color
```

> **Note on legacy files:** if your repo still contains an older
> `deploy/nginx/` directory (the previous in-container nginx variant), it
> is no longer used. You can delete it: `rm -rf deploy/nginx`.

---

## 9. Why this is zero-downtime

Three guarantees combined:

1. **The new container is fully healthy before any traffic moves.**
   `deploy.sh` polls Docker's health status (which itself probes
   `/healthz`) and refuses to swap if the new container hasn't gone
   `healthy` within 60 seconds.
2. **The upstream swap is atomic.** Rewriting a single included file plus
   `nginx -s reload` is the standard nginx zero-downtime pattern — old
   workers keep serving in-flight requests until they finish; new
   requests go to fresh workers using the new upstream.
3. **The old container only stops AFTER nginx has reloaded** and a 5-second
   drain window has elapsed, so any straggler requests on the old
   workers complete normally. The nginx server block also has
   `proxy_next_upstream error timeout http_502 http_503 http_504;` so any
   race condition during the swap auto-retries on the surviving upstream.

Net effect: no `502`, no dropped TCP connections, no truncated responses
during a deploy.

---

## 10. Migration notes (if upgrading from the in-container nginx variant)

If your server was previously running the older stack with nginx in a
container, follow these steps once on the server:

```bash
cd /opt/pelxa

# 1. Pull the new code
git pull origin main

# 2. Stop the old in-container stack (including the old nginx container)
docker compose down

# 3. Run the new bootstrap (installs host nginx, starts pelxa_blue on 5001)
chmod +x deploy/scripts/*.sh
./deploy/scripts/bootstrap.sh

# 4. Optional cleanup of the legacy folder
rm -rf deploy/nginx
```

Subsequent deploys: `./deploy/scripts/deploy.sh` as usual.
