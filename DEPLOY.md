# Cardex VPS dağıtım notları

DNS örneği: `cardex.script-app.cloud` → VPS IP (A kaydı).

## Güvenlik

- SSH şifrelerini repoda veya sohbette saklamayın; sunucuda SSH anahtarı kullanın.
- `.env` dosyalarını git’e eklemeyin.

## Mimari (öneri)

| Servis | Port (örnek) | Açıklama |
|--------|----------------|----------|
| Node API | 4000 | `backend` — reverse proxy arkasında |
| Next.js admin | 3000 | `admin` — `next start` veya ayrı port |

Nginx iki `server` bloğu veya tek domain altında `/api` → Node, `/` → Next ile birleştirilebilir.

## Örnek Nginx (HTTPS Let’s Encrypt sonrası)

API’yi alt yolla yayınlamak için:

```nginx
location /api/ {
    proxy_pass http://127.0.0.1:4000/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Admin için root’ta Next.js’e proxy veya ayrı subdomain (`admin.cardex...`).

## PM2 örneği

```bash
cd /path/to/car_data_app/backend && npm ci && npm run build
pm2 start dist/index.js --name cardex-api
```

```bash
cd /path/to/car_data_app/admin && npm ci && npm run build
pm2 start npm --name cardex-admin -- start
```

Ortam değişkenleri sunucuda `export` veya `ecosystem.config.cjs` ile verilir.

## Flutter uygulaması

İleride API kullanılacaksa `NEXT_PUBLIC_API_URL` ile aynı kökü mobil istemciye `dart-define` veya yapılandırma ile verin.
