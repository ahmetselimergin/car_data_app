# Plan — Google Sign-In (sonra)

Mobil uygulamaya Google ile giriş ekleme. Şu an yalnızca e-posta/şifre var.

## Önkoşullar (Supabase + Google Cloud)

1. Google Cloud Console → OAuth client (Web) oluştur
2. Authorized redirect URI: `https://idptwzbfoysdxjoachif.supabase.co/auth/v1/callback`
3. iOS / Android OAuth client’ları (bundle id + SHA-1)
4. Supabase → Authentication → Providers → Google:
   - Enable
   - Client IDs (web + native, virgülle)
   - Client Secret (web)
   - Skip nonce checks: iOS için genelde açık

## Uygulama işleri

- [ ] `google_sign_in` bağımlılığı
- [ ] iOS: `GIDClientID` + URL scheme (`Info.plist`)
- [ ] Android: gerekirse google-services / SHA-1
- [ ] `GoogleAuthService` + `SessionController.signInWithGoogle` (Supabase `signInWithIdToken`)
- [ ] Login / Register UI: Google butonu + divider
- [ ] l10n anahtarları (tr / en / es)
- [ ] `CLAUDE.md` / `README` notları

## Not

Admin (`admin_desktop`) e-posta/şifre ile kalabilir; Google öncelikle mobil Garaj için.
