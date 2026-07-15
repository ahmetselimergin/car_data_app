#!/usr/bin/env python3
"""Euro Repar Car Service (TR) servis noktaları -> workshops INSERT SQL.

euroreparcarservice-tr.com/servis-noktalari.html sayfasındaki tüm servis
noktalarını (varsayılan 34 sayfa) gezer, her kartın detay sayfasından
KESİN enlem/boylam (sitenin Google Maps linkinden) ve telefonu çeker.
Detay sayfasında koordinat yoksa adresi Nominatim ile geocode eder.

Sonuç: `public.workshops` tablosuna basılabilecek idempotent bir .sql dosyası
(önce eski Euro Repar kayıtlarını siler, sonra ekler).

Kullanım:
    python3 supabase/scripts/scrape_euro_repar.py
    python3 supabase/scripts/scrape_euro_repar.py --pages 3 --limit 5   # test
    python3 supabase/scripts/scrape_euro_repar.py --out workshops.sql

Sadece Python 3 standart kütüphanesi kullanır (ek pip paketi gerekmez).
Kibarlık: istekler arası gecikme + yerel .cache/ ile tekrar indirme yok.
Nominatim kullanım politikası: 1 istek/sn ve gerçek bir User-Agent şart.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from dataclasses import dataclass

BASE = "https://www.euroreparcarservice-tr.com"
LISTING = (
    BASE + "/servis-noktalari.html"
    "?map.center.lat=39.0015442&map.center.long=30.6892717"
    "&search.kilometer.radius.city=150"
    "&lat.reference=39.0015442&long.reference=30.6892717"
    "&has_search=0&page={page}"
)
UA = "car_data_app-euro-repar-scraper/1.0 (+https://euroreparcarservice-tr.com; contact: asease42@gmail.com)"
NOMINATIM = "https://nominatim.openstreetmap.org/search"

CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache")
SOURCE_TAG = "euro-repar"  # notes alanına yazılır; idempotent silme için kullanılır


@dataclass
class Workshop:
    name: str
    detail_url: str
    street: str
    city: str          # "Afyonkarahisar 03030"
    phone: str | None = None
    lat: float | None = None
    lng: float | None = None
    geo_source: str = ""  # "site" | "nominatim" | ""


# --------------------------------------------------------------------------- #
# HTTP (yerel cache + retry + kibar gecikme)
# --------------------------------------------------------------------------- #
def _cache_path(url: str) -> str:
    # URL'i kısaltmak sayfalar arası çakışmaya yol açıyordu (uzun listeleme
    # URL'inde &page=N kesme sınırından sonra kalıyordu). Tam URL hash'i ile
    # her sayfa/detay benzersiz bir cache dosyasına düşer.
    digest = hashlib.sha1(url.encode("utf-8")).hexdigest()[:20]
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", url)[:80]
    return os.path.join(CACHE_DIR, f"{slug}_{digest}.html")


def _encode_url(url: str) -> str:
    # URL'de Türkçe karakter (ör. .../sandıklı-...html) olabilir; urllib ASCII
    # ister, bu yüzden path ve query'yi yüzde-kodlayarak güvenli hale getir.
    parts = urllib.parse.urlsplit(url)
    path = urllib.parse.quote(parts.path, safe="/%")
    query = urllib.parse.quote(parts.query, safe="=&%")
    return urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, path, query, parts.fragment)
    )


def fetch(url: str, *, use_cache: bool = True, delay: float = 1.0) -> str:
    if use_cache:
        cp = _cache_path(url)
        if os.path.exists(cp):
            with open(cp, encoding="utf-8") as f:
                return f.read()
    last_err: Exception | None = None
    for attempt in range(4):
        try:
            req = urllib.request.Request(_encode_url(url), headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode("utf-8", errors="replace")
            if use_cache:
                os.makedirs(CACHE_DIR, exist_ok=True)
                with open(_cache_path(url), "w", encoding="utf-8") as f:
                    f.write(body)
            time.sleep(delay)  # kibar ol
            return body
        except Exception as e:  # noqa: BLE001 - ağ hatalarında geri çekil
            last_err = e
            time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"fetch başarısız: {url}: {last_err}")


# --------------------------------------------------------------------------- #
# Listeleme sayfası ayrıştırma
# --------------------------------------------------------------------------- #
def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(text)).strip()


CARD_SPLIT = re.compile(r'class="garage-card__container"')
RE_DETAIL = re.compile(r'href="(https://www\.euroreparcarservice-tr\.com/[^"]+\.html)"')
RE_NAME = re.compile(r'class="garage-card__name"[^>]*>(.*?)</a>', re.S)
RE_ADDR = re.compile(r'class="garage-card__address"[^>]*>(.*?)</p>', re.S)
RE_CP = re.compile(r'class="garage-card__cp"[^>]*>(.*?)</p>', re.S)


def parse_listing(html_text: str) -> list[Workshop]:
    parts = CARD_SPLIT.split(html_text)[1:]  # ilk parça kart öncesi
    out: list[Workshop] = []
    for seg in parts:
        m_detail = RE_DETAIL.search(seg)
        m_name = RE_NAME.search(seg)
        if not (m_detail and m_name):
            continue
        m_addr = RE_ADDR.search(seg)
        m_cp = RE_CP.search(seg)
        out.append(
            Workshop(
                name=_clean(m_name.group(1)),
                detail_url=html.unescape(m_detail.group(1)),
                street=_clean(m_addr.group(1)) if m_addr else "",
                city=_clean(m_cp.group(1)) if m_cp else "",
            )
        )
    return out


# --------------------------------------------------------------------------- #
# Detay sayfası: kesin koordinat + telefon
# --------------------------------------------------------------------------- #
RE_GMAPS = re.compile(r'google\.com/maps/search/\?api=1&query=([0-9.\-]+)%2C([0-9.\-]+)')
RE_PHONE = re.compile(r'Telefon[^<:]*Numarası\s*:?\s*</strong>\s*([0-9 ()+]{7,})', re.I)


def enrich_from_detail(w: Workshop, *, delay: float) -> None:
    try:
        page = fetch(w.detail_url, delay=delay)
    except RuntimeError as e:
        print(f"  ! detay indirilemedi: {w.name}: {e}", file=sys.stderr)
        return
    m = RE_GMAPS.search(page)
    if m:
        w.lat, w.lng = float(m.group(1)), float(m.group(2))
        w.geo_source = "site"
    mp = RE_PHONE.search(page)
    if mp:
        w.phone = normalize_phone(mp.group(1))


def normalize_phone(raw: str) -> str | None:
    digits = re.sub(r"\D", "", raw)
    # TR numaraları: "0 541 221 20 29" -> 05412212029 (11) veya 5412212029 (10)
    if len(digits) == 11 and digits.startswith("0"):
        digits = digits[1:]
    if digits.startswith("90") and len(digits) == 12:
        digits = digits[2:]
    if len(digits) == 10:
        return "+90" + digits
    return None  # tanınmayan format -> boş bırak


# --------------------------------------------------------------------------- #
# Nominatim yedek geocode
# --------------------------------------------------------------------------- #
def geocode_nominatim(w: Workshop, *, delay: float = 1.1) -> None:
    query = ", ".join(p for p in (w.street, w.city, "Türkiye") if p)
    if not query:
        return
    params = urllib.parse.urlencode(
        {"q": query, "format": "json", "limit": 1, "countrycodes": "tr"}
    )
    url = f"{NOMINATIM}?{params}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        time.sleep(delay)  # Nominatim: >=1 sn/istek zorunlu
        if data:
            w.lat = float(data[0]["lat"])
            w.lng = float(data[0]["lon"])
            w.geo_source = "nominatim"
    except Exception as e:  # noqa: BLE001
        print(f"  ! nominatim başarısız: {w.name}: {e}", file=sys.stderr)


# --------------------------------------------------------------------------- #
# İl (şehir) — posta kodunun ilk iki hanesi = plaka kodu
# --------------------------------------------------------------------------- #
PLAKA = {
    "01": "Adana", "02": "Adıyaman", "03": "Afyonkarahisar", "04": "Ağrı",
    "05": "Amasya", "06": "Ankara", "07": "Antalya", "08": "Artvin",
    "09": "Aydın", "10": "Balıkesir", "11": "Bilecik", "12": "Bingöl",
    "13": "Bitlis", "14": "Bolu", "15": "Burdur", "16": "Bursa",
    "17": "Çanakkale", "18": "Çankırı", "19": "Çorum", "20": "Denizli",
    "21": "Diyarbakır", "22": "Edirne", "23": "Elazığ", "24": "Erzincan",
    "25": "Erzurum", "26": "Eskişehir", "27": "Gaziantep", "28": "Giresun",
    "29": "Gümüşhane", "30": "Hakkari", "31": "Hatay", "32": "Isparta",
    "33": "Mersin", "34": "İstanbul", "35": "İzmir", "36": "Kars",
    "37": "Kastamonu", "38": "Kayseri", "39": "Kırklareli", "40": "Kırşehir",
    "41": "Kocaeli", "42": "Konya", "43": "Kütahya", "44": "Malatya",
    "45": "Manisa", "46": "Kahramanmaraş", "47": "Mardin", "48": "Muğla",
    "49": "Muş", "50": "Nevşehir", "51": "Niğde", "52": "Ordu",
    "53": "Rize", "54": "Sakarya", "55": "Samsun", "56": "Siirt",
    "57": "Sinop", "58": "Sivas", "59": "Tekirdağ", "60": "Tokat",
    "61": "Trabzon", "62": "Tunceli", "63": "Şanlıurfa", "64": "Uşak",
    "65": "Van", "66": "Yozgat", "67": "Zonguldak", "68": "Aksaray",
    "69": "Bayburt", "70": "Karaman", "71": "Kırıkkale", "72": "Batman",
    "73": "Şırnak", "74": "Bartın", "75": "Ardahan", "76": "Iğdır",
    "77": "Yalova", "78": "Karabük", "79": "Kilis", "80": "Osmaniye",
    "81": "Düzce",
}


def province_of(w: Workshop) -> str | None:
    # Posta kodunu önce şehir alanında, sonra sokak adresinde ara.
    for text in (w.city, w.street):
        m = re.search(r"\b(\d{5})\b", text or "")
        if m:
            return PLAKA.get(m.group(1)[:2])
    return None


# --------------------------------------------------------------------------- #
# SQL üretimi
# --------------------------------------------------------------------------- #
def sql_str(value: str | None) -> str:
    if not value:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def sql_num(value: float | None) -> str:
    return "null" if value is None else repr(value)


def build_sql(workshops: list[Workshop]) -> str:
    lines: list[str] = [
        "-- Euro Repar Car Service (TR) servis noktaları.",
        "-- scrape_euro_repar.py tarafından üretildi. Idempotent: önce eski",
        f"-- '{SOURCE_TAG}:' etiketli kayıtları siler, sonra yeniden ekler.",
        "-- Önce 20260714000001_workshops_geo.sql migration'ının çalıştığından emin ol.",
        "begin;",
        f"delete from public.workshops where notes like '{SOURCE_TAG}:%';",
        "",
        "insert into public.workshops "
        "(name, phone, address, city, lat, lng, notes, active)",
        "values",
    ]
    rows: list[str] = []
    for w in workshops:
        address = ", ".join(p for p in (w.street, w.city) if p)
        notes = f"{SOURCE_TAG}:{w.detail_url}"
        rows.append(
            "  ("
            f"{sql_str(w.name)}, {sql_str(w.phone)}, {sql_str(address)}, "
            f"{sql_str(province_of(w))}, "
            f"{sql_num(w.lat)}, {sql_num(w.lng)}, {sql_str(notes)}, true)"
        )
    lines.append(",\n".join(rows) + ";")
    lines.append("")
    lines.append("commit;")
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="Euro Repar TR servis noktası scraper")
    ap.add_argument("--pages", type=int, default=34, help="taranacak sayfa sayısı")
    ap.add_argument("--limit", type=int, default=0, help="toplam servis sınırı (test)")
    ap.add_argument("--out", default="workshops_euro_repar.sql", help="çıktı .sql yolu")
    ap.add_argument("--delay", type=float, default=1.0, help="istekler arası saniye")
    ap.add_argument("--no-detail", action="store_true",
                    help="detay sayfasını atla, doğrudan Nominatim geocode kullan")
    ap.add_argument("--no-cache", action="store_true", help="yerel cache kullanma")
    args = ap.parse_args()

    use_cache = not args.no_cache

    workshops: list[Workshop] = []
    for page in range(1, args.pages + 1):
        print(f"[listeleme] sayfa {page}/{args.pages}", file=sys.stderr)
        page_html = fetch(LISTING.format(page=page), use_cache=use_cache, delay=args.delay)
        workshops.extend(parse_listing(page_html))
        if args.limit and len(workshops) >= args.limit:
            workshops = workshops[: args.limit]
            break

    # Güvenlik ağı: aynı servis birden fazla sayfada çıkarsa (veya pagination
    # bozulursa) detay URL'ine göre tekilleştir.
    seen: set[str] = set()
    unique: list[Workshop] = []
    for w in workshops:
        if w.detail_url in seen:
            continue
        seen.add(w.detail_url)
        unique.append(w)
    dropped = len(workshops) - len(unique)
    workshops = unique
    print(
        f"[listeleme] {len(workshops)} benzersiz servis"
        + (f" ({dropped} tekrar atlandı)" if dropped else ""),
        file=sys.stderr,
    )

    for i, w in enumerate(workshops, 1):
        print(f"[detay {i}/{len(workshops)}] {w.name}", file=sys.stderr)
        if not args.no_detail:
            enrich_from_detail(w, delay=args.delay)
        if w.lat is None:  # site koordinatı yoksa -> Nominatim yedek
            geocode_nominatim(w)

    sql = build_sql(workshops)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(sql)

    with_geo = sum(1 for w in workshops if w.lat is not None)
    from_site = sum(1 for w in workshops if w.geo_source == "site")
    from_nom = sum(1 for w in workshops if w.geo_source == "nominatim")
    with_phone = sum(1 for w in workshops if w.phone)
    print(
        f"\nBitti: {len(workshops)} servis -> {args.out}\n"
        f"  koordinatlı: {with_geo} (site: {from_site}, nominatim: {from_nom})\n"
        f"  telefonlu:   {with_phone}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
