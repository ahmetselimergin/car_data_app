# Cardex API

Express 5 + TypeScript + **Drizzle ORM** + PostgreSQL.

## DB seçenekleri (kod aynı, sadece `DATABASE_URL` değişir)

### 1) Neon (önerilen — sıfır kurulum)
- [neon.tech](https://neon.tech) → ücretsiz proje → bağlantı string'i
- `cp .env.example .env` ve `DATABASE_URL` satırını doldur

### 2) Homebrew Postgres (yerel, native)
```bash
brew install postgresql@16
brew services start postgresql@16
createdb cardex
# .env: DATABASE_URL=postgres://$USER@localhost:5432/cardex
```

### 3) Docker (yerel, izole)
İstersen `docker-compose.yml` ile çalıştırırsın; bu projeye opsiyonel.

## İlk kurulum

```bash
npm install
cp .env.example .env        # DATABASE_URL doldur
npm run db:push             # Drizzle şemayı uygular
npm run dev                 # http://localhost:4000
```

Sağlık: `GET /health` · API kökü: `GET /api/v1`

## Uçlar (REST, JSON)

- `cars`: `GET/POST /api/v1/cars` · `GET/PATCH/DELETE /api/v1/cars/:id`
- `brands`, `workshops`, `agreements`: aynı şablon
- `agreements?workshopId=…` filtreleme
