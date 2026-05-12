#!/usr/bin/env bash
# deploy.sh — cardex.script-app.cloud tek seferlik VPS kurulum + deploy
# Kullanım: bash deploy.sh
set -euo pipefail

SERVER_IP="72.62.39.133"
SERVER_USER="root"
REMOTE_DIR="/opt/cardex"
DOMAIN="cardex.script-app.cloud"
LOCAL_PROJECT="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}▶ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
error() { echo -e "${RED}✖ $*${NC}"; exit 1; }

# ─── Girdi ────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  Cardex Deploy — $DOMAIN"
echo "════════════════════════════════════════"
echo ""
read -rsp "SSH şifresi (root@$SERVER_IP): " SSH_PASS; echo
read -rsp "PostgreSQL şifresi (yeni belirleyin): " PG_PASS;  echo
read -rp  "Firebase JSON yolu (boş bırakılabilir): " FB_PATH

[[ -z "$SSH_PASS" ]] && error "SSH şifresi gerekli."
[[ -z "$PG_PASS"  ]] && error "PostgreSQL şifresi gerekli."

PG_USER="cardex"
PG_DB="cardex"
DATABASE_URL="postgresql://${PG_USER}:${PG_PASS}@localhost:5432/${PG_DB}"

# ─── sshpass kontrolü ─────────────────────────────────────────────────────────
if ! command -v sshpass &>/dev/null; then
  warn "sshpass kuruluyor..."
  [[ "$(uname)" == "Darwin" ]] \
    && brew install hudochenkov/sshpass/sshpass \
    || apt-get install -y sshpass
fi

export SSHPASS="$SSH_PASS"
SSH="sshpass -e ssh -o StrictHostKeyChecking=no"
SCP="sshpass -e scp -o StrictHostKeyChecking=no"

# ─── 1. Kodu gönder ───────────────────────────────────────────────────────────
info "Kod sunucuya gönderiliyor..."
sshpass -e rsync -avz \
  --exclude node_modules --exclude .git \
  --exclude .env --exclude .env.local \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$LOCAL_PROJECT/" "$SERVER_USER@$SERVER_IP:$REMOTE_DIR/"

# Firebase service account (opsiyonel)
FB_ENV_LINE="# FIREBASE_SERVICE_ACCOUNT_PATH="
if [[ -n "$FB_PATH" && -f "$FB_PATH" ]]; then
  info "Firebase service account gönderiliyor..."
  $SCP "$FB_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_DIR/backend/firebase-service-account.json"
  FB_ENV_LINE="FIREBASE_SERVICE_ACCOUNT_PATH=$REMOTE_DIR/backend/firebase-service-account.json"
else
  warn "Firebase atlandı (sonra ekleyebilirsiniz)."
fi

# ─── 2. Uzak kurulum scripti ──────────────────────────────────────────────────
# Tüm değişkenleri burada genişletiyoruz; uzakta sabit değerler çalışır.
REMOTE_SCRIPT=$(cat << SCRIPT
#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; NC='\033[0m'
info() { echo -e "\${G}▶ \$*\${NC}"; }
warn() { echo -e "\${Y}⚠ \$*\${NC}"; }

# ── Node 20 ───────────────────────────────────────────────────────────────────
info "Node.js 20 kontrol ediliyor..."
if ! node -v 2>/dev/null | grep -q "v20"; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
  apt-get install -y nodejs >/dev/null
fi
npm install -g pm2 >/dev/null

# ── Nginx + Certbot ───────────────────────────────────────────────────────────
info "Nginx + Certbot kuruluyor..."
apt-get install -y nginx certbot python3-certbot-nginx >/dev/null
systemctl enable nginx

# ── PostgreSQL ────────────────────────────────────────────────────────────────
info "PostgreSQL kuruluyor..."
apt-get install -y postgresql postgresql-contrib >/dev/null
systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${PG_USER}'" | grep -q 1 \
  || sudo -u postgres psql -c "CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASS}';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${PG_DB}'" | grep -q 1 \
  || sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};"

# ── Backend .env ──────────────────────────────────────────────────────────────
info "Backend .env yazılıyor..."
cat > ${REMOTE_DIR}/backend/.env << 'ENVEOF'
DATABASE_URL=${DATABASE_URL}
PORT=4000
CORS_ORIGIN=https://${DOMAIN}
${FB_ENV_LINE}
ENVEOF

# ── Backend build ─────────────────────────────────────────────────────────────
info "Backend kuruluyor..."
cd ${REMOTE_DIR}/backend
npm ci --silent
npm run build
npm run db:push

# ── Admin .env.local ──────────────────────────────────────────────────────────
info "Admin .env.local yazılıyor..."
echo "NEXT_PUBLIC_API_URL=https://${DOMAIN}" > ${REMOTE_DIR}/admin/.env.local

# ── Admin build ───────────────────────────────────────────────────────────────
info "Admin kuruluyor..."
cd ${REMOTE_DIR}/admin
npm ci --silent
npm run build

# ── PM2 ───────────────────────────────────────────────────────────────────────
info "PM2 servisleri başlatılıyor..."
pm2 delete cardex-api   2>/dev/null || true
pm2 delete cardex-admin 2>/dev/null || true

cd ${REMOTE_DIR}/backend && pm2 start dist/index.js --name cardex-api
cd ${REMOTE_DIR}/admin   && pm2 start npm --name cardex-admin -- start

pm2 save
eval \$(pm2 startup systemd -u root --hp /root | tail -1)

# ── Nginx ─────────────────────────────────────────────────────────────────────
info "Nginx yapılandırılıyor..."
cat > /etc/nginx/sites-available/cardex << 'NGINXEOF'
server {
    listen 80;
    server_name ${DOMAIN};
    client_max_body_size 10M;

    location /api/ {
        proxy_pass         http://127.0.0.1:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }

    location /uploads/ {
        proxy_pass         http://127.0.0.1:4000/uploads/;
        proxy_http_version 1.1;
        proxy_set_header   Host \$host;
    }

    location /health {
        proxy_pass         http://127.0.0.1:4000/health;
        proxy_http_version 1.1;
    }

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   Upgrade           \$http_upgrade;
        proxy_set_header   Connection        "upgrade";
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_cache_bypass                   \$http_upgrade;
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
ln -sf /etc/nginx/sites-available/cardex /etc/nginx/sites-enabled/cardex
nginx -t
systemctl reload nginx

# ── SSL ───────────────────────────────────────────────────────────────────────
info "SSL sertifikası alınıyor..."
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m root@${DOMAIN} \
  && info "SSL OK" \
  || warn "SSL atlandı — DNS yayılmamış olabilir. Sonra: certbot --nginx -d ${DOMAIN}"

# ── Sonuç ─────────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
pm2 list
echo ""
curl -sf http://localhost:4000/health && echo "✔ Backend OK" || echo "✖ Backend yanıt vermiyor"
echo ""
echo "  https://${DOMAIN}        → Admin"
echo "  https://${DOMAIN}/api/v1 → API"
echo "  https://${DOMAIN}/health → Sağlık"
echo "════════════════════════════════════════"
SCRIPT
)

# ─── 3. Uzakta çalıştır ───────────────────────────────────────────────────────
info "Sunucuda kurulum çalıştırılıyor..."
echo "$REMOTE_SCRIPT" | $SSH "$SERVER_USER@$SERVER_IP" bash

info "Deploy tamamlandı!"
echo ""
echo "  Admin  → https://$DOMAIN"
echo "  API    → https://$DOMAIN/api/v1"
echo "  Sağlık → https://$DOMAIN/health"
