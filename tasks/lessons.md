# Lessons

## 2026-07-14 — Doğrulama sinyalini geçiştirme

**Bağlam:** Euro Repar scraper. Kendi doğrulamam "10 tekrar eden isim" dedi;
ben bunu "zincir servisler, normal" diye geçiştirdim. Gerçekte scraper'ın
cache-key'i URL'i 180 karaktere kesiyordu ve uzun listeleme URL'inde `&page=N`
kesme sınırından sonra kaldığı için tüm sayfalar tek cache dosyasına çakışıyordu
→ 10 servis × 34 sayfa = 340 kopya. Kullanıcı fark etti.

**Kural:**
- Kendi doğrulama çıktın bir anomali gösteriyorsa (tekrar, beklenmedik sayı),
  ONU AÇIKLA — "muhtemelen normaldir" deyip geçme. 1-2 komutla kanıtla
  (benzersiz sayısı, örnek satırlar).
- Cache/dosya anahtarlarında URL'i KESME. Ayırt edici kısım (ör. `page=N`)
  sonda olabilir. Tam URL hash'i kullan.
- Sayfalı (paginated) scraper'da her zaman detay/benzersiz anahtara göre
  dedup güvenlik ağı koy; siteye/parse'a güvenme.
