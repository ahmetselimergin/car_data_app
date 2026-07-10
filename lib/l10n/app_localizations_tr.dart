// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Garaj';

  @override
  String get navMyCars => 'Araçlarım';

  @override
  String get navReminders => 'Hatırlatıcılar';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageSpanish => 'İspanyolca';

  @override
  String get unitsLabel => 'Birimler';

  @override
  String get unitsMetric => 'Metrik (km)';

  @override
  String get unitsImperial => 'İmparatorluk (mil)';

  @override
  String get unitKmShort => 'km';

  @override
  String get unitMilesShort => 'mil';

  @override
  String get distanceLabelKm => 'Kilometre';

  @override
  String get distanceLabelMi => 'Mil';

  @override
  String get distanceHintKm => 'Örn. 145000 veya 145.000';

  @override
  String get distanceHintMi => 'Örn. 90000';

  @override
  String get distanceRequiredKm => 'Kilometre gerekli';

  @override
  String get distanceRequiredMi => 'Mil gerekli';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signOutSubtitle =>
      'Bu cihazdaki oturumu kapatır; araç verileri silinmez.';

  @override
  String get signOutDialogTitle => 'Çıkış';

  @override
  String get signOutConfirm => 'Oturumu kapatmak istiyor musunuz?';

  @override
  String get cancel => 'İptal';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeLight => 'Aydınlık';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get notificationsLabel => 'Bildirimler';

  @override
  String get notificationsSubtitle =>
      'Hatırlatıcı tarihinden 7 gün önce bildirim gönderilir.';

  @override
  String get versionLabel => 'Sürüm';

  @override
  String get emptyGarageTitle => 'Garaja hoş geldin';

  @override
  String get emptyGarageSubtitle =>
      'Araçlarını ekle, sigorta, kasko, muayene gibi tarihleri takip et ve bakım geçmişini tek yerde tut.';

  @override
  String get addFirstCar => 'İlk aracını ekle';

  @override
  String get needsAttention => 'Dikkat gerekenler';

  @override
  String get maintenanceHistory => 'Bakım geçmişi';

  @override
  String get seeAll => 'Tümünü gör';

  @override
  String get noMaintenanceYet => 'Henüz bakım kaydı yok';

  @override
  String get noMaintenanceHint =>
      'Yağ değişimi, lastik vb. eklemek için + tuşu';

  @override
  String get addReminder => 'Hatırlatıcı ekle';

  @override
  String get newCar => 'Yeni araç';

  @override
  String get statMaintenanceCost => 'Bakım Maliyeti';

  @override
  String get statLastService => 'Son Servis';

  @override
  String get statTotal => 'Toplam';

  @override
  String get today => 'Bugün';

  @override
  String daysCount(int days) {
    return '$days gün';
  }

  @override
  String monthsCount(int months) {
    return '$months ay';
  }

  @override
  String yearsCount(int years) {
    return '$years yıl';
  }

  @override
  String get allUpToDate => 'Hepsi güncel';

  @override
  String get noUpcomingReminders =>
      'Bu araç için yaklaşan bir hatırlatıcı yok.';

  @override
  String get add => 'Ekle';

  @override
  String get expired => 'Süresi doldu';

  @override
  String get remainingUntilExpiry => 'Bitişe kalan';

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks hafta önce';
  }

  @override
  String monthsAgo(int months) {
    return '$months ay önce';
  }

  @override
  String get flagOfficialShort => 'Resmi';

  @override
  String get flagWarrantyShort => 'Garanti';

  @override
  String get flagReceiptShort => 'Fiş';

  @override
  String get flagInsuranceShort => 'Sigorta';

  @override
  String get remindersTitle => 'Hatırlatıcılar';

  @override
  String get allRemindersEmpty =>
      'Henüz hatırlatıcı yok. Bir araca girip sigorta, kasko, muayene veya egzoz tarihi ekle.';

  @override
  String genericError(String error) {
    return 'Hata: $error';
  }

  @override
  String get loginTitle => 'Giriş yap';

  @override
  String get loginSubtitle =>
      'Giriş Supabase Authentication ile yapılır. Verileriniz isteğe bağlı olarak sunucuya taşınana kadar araç kayıtları bu cihazda kalır.';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get emailRequired => 'E-posta gerekli';

  @override
  String get loginIdLabel => 'E-posta veya kullanıcı adı';

  @override
  String get loginIdRequired => 'E-posta veya kullanıcı adı gerekli';

  @override
  String get usernameLabel => 'Kullanıcı adı';

  @override
  String get usernameRequired => 'Kullanıcı adı gerekli';

  @override
  String get usernameInvalid =>
      'Kullanıcı adı: 3–32 karakter, küçük harf, rakam, alt çizgi';

  @override
  String get usernameTaken => 'Bu kullanıcı adı alınmış';

  @override
  String get emailInvalid => 'Geçerli bir e-posta girin';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get showPassword => 'Göster';

  @override
  String get hidePassword => 'Gizle';

  @override
  String get passwordMinLength => 'En az 6 karakter';

  @override
  String get signInButton => 'Giriş yap';

  @override
  String get noAccountQuestion => 'Hesabınız yok mu?';

  @override
  String get registerLink => 'Kayıt olun';

  @override
  String get loginFooterNote =>
      'Şifre yalnızca giriş anında iletilir ve Supabase üzerinden doğrulanır.';

  @override
  String get registerAppBarTitle => 'Kayıt ol';

  @override
  String get registerTitle => 'Hesap oluştur';

  @override
  String get registerSubtitle =>
      'Kayıt Supabase ile oluşturulur. Adınızı isteğe bağlı olarak profilde gösterebilirsiniz.';

  @override
  String get displayNameLabel => 'Ad Soyad (isteğe bağlı)';

  @override
  String get confirmPasswordLabel => 'Şifre tekrar';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get registerButton => 'Kayıt ol';

  @override
  String get alreadyHaveAccountSignIn => 'Zaten hesabım var — giriş';

  @override
  String get registerFooterNote =>
      'Kayıt şifresi yalnızca doğrulama için kullanılır, cihaza yazılmaz.';

  @override
  String get transmissionManual => 'Manuel';

  @override
  String get transmissionAutomatic => 'Otomatik';

  @override
  String get transmissionSemiAutomatic => 'Yarı otomatik';

  @override
  String get transmissionCvt => 'CVT';

  @override
  String get fuelPetrol => 'Benzin';

  @override
  String get fuelDiesel => 'Dizel';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelHybrid => 'Hibrit';

  @override
  String get fuelPlugInHybrid => 'Plug-in hibrit';

  @override
  String get fuelElectric => 'Elektrik';

  @override
  String get deleteCarTitle => 'Aracı sil';

  @override
  String deleteCarMessage(String brand, String model) {
    return '$brand $model kaydı ve ilişkili bakım / hatırlatıcılar silinecek.';
  }

  @override
  String get delete => 'Sil';

  @override
  String get carDeleted => 'Araç silindi';

  @override
  String deleteFailed(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String get cropPhotoTitle => 'Fotoğrafı kırp';

  @override
  String get cropTitle => 'Kırp';

  @override
  String get cropPluginMissing =>
      'Kırpma henüz yüklü değil. Uygulamayı tamamen kapatıp yeniden başlatın. Şimdilik fotoğraf kırpılmadan kullanılıyor.';

  @override
  String cropSkipped(String error) {
    return 'Kırpma atlandı: $error';
  }

  @override
  String photoPickFailed(String error) {
    return 'Fotoğraf seçilemedi: $error';
  }

  @override
  String get takePhoto => 'Kameradan çek';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get recrop => 'Yeniden kırp';

  @override
  String get removePhoto => 'Fotoğrafı kaldır';

  @override
  String get yearNotSelected => 'Yıl seçilmedi';

  @override
  String get transmissionNotSelected => 'Şanzıman tipi seçilmedi';

  @override
  String get fuelNotSelected => 'Yakıt tipi seçilmedi';

  @override
  String get removingBackground => 'Arka plan kaldırılıyor...';

  @override
  String get backgroundRemovalFailed =>
      'Arka plan kaldırılamadı, orijinal fotoğraf kullanıldı.';

  @override
  String get carUpdated => 'Araç güncellendi';

  @override
  String get carAdded => 'Araç eklendi';

  @override
  String get backgroundPreviewFailed =>
      'Arka plan önizlemesi oluşturulamadı; orijinal fotoğraf gösteriliyor.';

  @override
  String get editCarTitle => 'Aracı düzenle';

  @override
  String get newCarTitle => 'Yeni araç';

  @override
  String get deleteCarTooltip => 'Aracı sil';

  @override
  String get cardColorLabel => 'Kart rengi';

  @override
  String get cardColorAuto => 'Otomatik';

  @override
  String get autoRemoveBackground => 'Arka planı otomatik kaldır';

  @override
  String get plateLabel => 'Plaka';

  @override
  String get plateHint => '34 ABC 1234';

  @override
  String get plateRequired => 'Plaka gerekli';

  @override
  String get plateForbiddenLetters =>
      'Plakada Ç, Ş, İ, Ö, Ü, Ğ kullanılmaz; örn. 34 ABC 1234';

  @override
  String get plateInvalidFormat =>
      'İl 01-81, harf 1-3 (ÇŞİÖÜĞ yok), rakam: 1 harf→4; 2 harf→3-4; 3 harf→2-3';

  @override
  String get brandLabel => 'Marka';

  @override
  String get selectBrand => 'Marka seç';

  @override
  String get customBrandLabel => 'Marka adı';

  @override
  String get customBrandHint => 'Markanın tam adı';

  @override
  String get customBrandRequired => 'Marka adı gerekli';

  @override
  String get modelLabel => 'Model';

  @override
  String get selectModel => 'Model seç';

  @override
  String get customModelLabel => 'Model adı';

  @override
  String get customModelHint => 'Modelin tam adı';

  @override
  String get customModelRequired => 'Model adı gerekli';

  @override
  String get yearLabel => 'Yıl';

  @override
  String get selectYear => 'Yıl seç';

  @override
  String get mileageLabel => 'Kilometre';

  @override
  String get mileageHint => 'Örn. 145000 veya 145.000';

  @override
  String get mileageInvalid => 'Geçerli km girin';

  @override
  String get transmissionLabel => 'Şanzıman tipi';

  @override
  String get selectTransmission => 'Şanzıman seç';

  @override
  String get fuelTypeLabel => 'Yakıt tipi';

  @override
  String get selectFuel => 'Yakıt seç';

  @override
  String get updateButton => 'Güncelle';

  @override
  String get saveButton => 'Kaydet';

  @override
  String get catalogOther => 'Diğer';

  @override
  String get officialService => 'Resmi servis';

  @override
  String get warranty => 'Garanti';

  @override
  String get insurance => 'Sigorta';

  @override
  String get invoiceReceipt => 'Fatura/fiş';

  @override
  String get maintenanceLogTitle => 'Bakım günlüğü';

  @override
  String get addMaintenance => 'Bakım ekle';

  @override
  String get maintenanceEmpty =>
      'Henüz bakım kaydı yok.\nİlk bakımı eklemek için + tuşuna bas.';

  @override
  String get deleteTooltip => 'Sil';

  @override
  String get totalSpending => 'Toplam harcama';

  @override
  String get recordsCount => 'kayıt';

  @override
  String get newMaintenanceEntry => 'Yeni bakım kaydı';

  @override
  String get titleOptional => 'Başlık (isteğe bağlı)';

  @override
  String get titleHint => 'Boş bırakırsanız seçtiklerinizden oluşturulur';

  @override
  String get titleOrItemsRequired => 'Başlık yazın veya alttan işlem seçin';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get kmLabel => 'KM';

  @override
  String get kmRequired => 'KM gerekli';

  @override
  String get enterValidNumber => 'Geçerli bir sayı gir';

  @override
  String get costLabel => 'Maliyet (₺)';

  @override
  String get optional => 'İsteğe bağlı';

  @override
  String get costRequired => 'Maliyet gerekli';

  @override
  String get enterValidAmount => 'Geçerli bir tutar gir';

  @override
  String get costOptionalWithWarranty =>
      'Garanti veya sigorta seçiliyse tutarı boş veya 0 bırakabilirsiniz.';

  @override
  String get additionalInfo => 'Ek bilgiler';

  @override
  String get serviceShopLabel => 'Servis veya usta (isteğe bağlı)';

  @override
  String get workPerformed => 'Yapılan işlemler';

  @override
  String get searchWorkHint => 'İşlem ara…';

  @override
  String get clear => 'Temizle';

  @override
  String get noMatchingWork => 'Aramanızla eşleşen işlem yok';

  @override
  String get noItemsSelectedHint =>
      'Henüz seçim yok · Kutunun içinde kaydırarak tümünü görün';

  @override
  String itemsSelectedCount(int count) {
    return '$count işlem seçildi';
  }

  @override
  String get paymentAndDocuments => 'Ödeme ve belge';

  @override
  String get doneAtAuthorizedService => 'Resmi yetkili serviste yapıldı';

  @override
  String get underWarranty => 'Garanti kapsamındaydı';

  @override
  String get invoiceReceived => 'Fatura veya fiş alındı';

  @override
  String get coveredByInsurance => 'Sigorta / kasko karşıladı';

  @override
  String get maintenanceLogTooltip => 'Bakım günlüğü';

  @override
  String get remindersEmptyTitle => 'Henüz hatırlatıcı eklenmemiş.';

  @override
  String get remindersEmptySubtitle =>
      'Sigorta, kasko, muayene veya egzoz bitiş tarihi ekleyebilirsin.';

  @override
  String deleteReminderMessage(String type) {
    return '$type hatırlatıcısı silinsin mi?';
  }

  @override
  String get dismiss => 'Vazgeç';

  @override
  String get selectExpiryDate => 'Bitiş tarihini seç';

  @override
  String get expiryDateRequired => 'Lütfen bir bitiş tarihi seç';

  @override
  String get newReminder => 'Yeni hatırlatıcı';

  @override
  String get editReminder => 'Hatırlatıcıyı düzenle';

  @override
  String get expiryDateLabel => 'Bitiş tarihi';

  @override
  String get dateNotSelected => 'Tarih seçilmedi';

  @override
  String get reminderTypeInsurance => 'Sigorta';

  @override
  String get reminderTypeComprehensive => 'Kasko';

  @override
  String get reminderTypeInspection => 'Muayene';

  @override
  String get reminderTypeEmissions => 'Egzoz';

  @override
  String get statusExpired => 'Süresi Dolmuş';

  @override
  String get statusCritical => 'Kritik';

  @override
  String get statusApproaching => 'Yaklaşıyor';

  @override
  String get statusSafe => 'Güvenli';

  @override
  String get lastDayToday => 'Bugün son gün';

  @override
  String get lastDayTomorrow => 'Yarın son gün';

  @override
  String daysRemaining(int days) {
    return '$days gün kaldı';
  }

  @override
  String expiredDaysAgo(int days) {
    return '$days gün önce doldu';
  }

  @override
  String get authInvalidEmail => 'Geçersiz e-posta adresi.';

  @override
  String get authUserDisabled => 'Bu hesap devre dışı bırakılmış.';

  @override
  String get authUserNotFound => 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';

  @override
  String get authInvalidCredential =>
      'Giriş bilgileri geçersiz veya süresi dolmuş.';

  @override
  String get authEmailInUse => 'Bu e-posta adresi zaten kullanılıyor.';

  @override
  String get authWeakPassword => 'Şifre çok zayıf; daha güçlü bir şifre seçin.';

  @override
  String get authOperationNotAllowed =>
      'Bu giriş yöntemi etkin değil (Supabase Auth).';

  @override
  String get authNetworkError => 'Ağ hatası. Bağlantınızı kontrol edin.';

  @override
  String get authTooManyRequests =>
      'Çok fazla deneme. Bir süre sonra tekrar deneyin.';

  @override
  String authSignInFailed(String code) {
    return 'Giriş işlemi tamamlanamadı ($code).';
  }

  @override
  String get authEmailConfirmationRequired =>
      'Giriş yapmadan önce e-postanızdaki onay bağlantısını kullanın.';

  @override
  String get notificationChannelName => 'Araç Hatırlatıcıları';

  @override
  String get notificationChannelDescription =>
      'Sigorta, kasko, muayene gibi tarihlerin yaklaştığını bildirir.';

  @override
  String notificationTitle(String type) {
    return '$type hatırlatması';
  }

  @override
  String notificationBody(int days, String type) {
    return '$type bitişine $days gün kaldı.';
  }

  @override
  String notificationBodyWithCar(int days, String type, String car) {
    return '$car için $type bitişine $days gün kaldı.';
  }

  @override
  String get maintOilChange => 'Yağ değişimi';

  @override
  String get maintOilFilter => 'Yağ filtresi';

  @override
  String get maintAirFilter => 'Hava filtresi';

  @override
  String get maintCabinFilter => 'Polen filtresi';

  @override
  String get maintFuelFilter => 'Yakıt filtresi';

  @override
  String get maintWaterFilterDiesel => 'Su filtresi (dizel)';

  @override
  String get maintFrontBrakePads => 'Ön fren balatası';

  @override
  String get maintRearBrakePads => 'Arka fren balatası';

  @override
  String get maintBrakeDisc => 'Fren diski';

  @override
  String get maintBrakeFluid => 'Fren hidroliği';

  @override
  String get maintTieRodEnds => 'Rot başları';

  @override
  String get maintBallJoint => 'Rotil';

  @override
  String get maintShockAbsorber => 'Amortisör';

  @override
  String get maintTireChangeRotation => 'Lastik değişimi / rotasyon';

  @override
  String get maintWheelBalance => 'Balans ayarı';

  @override
  String get maintBattery => 'Akü';

  @override
  String get maintSparkPlugsIgnition => 'Buji / ateşleme';

  @override
  String get maintTimingBeltChain => 'Triger seti / zincir';

  @override
  String get maintClutch => 'Debriyaj';

  @override
  String get maintCoolantHose => 'Soğutma suyu / hortum';

  @override
  String get maintAcService => 'Klima gazı / bakım';

  @override
  String get maintExhaustMuffler => 'Egzoz / susturucu';

  @override
  String get maintWiper => 'Silecek';

  @override
  String get maintHeadlightBulb => 'Far / sinyal ampulü';

  @override
  String get maintGeneralInspection => 'Genel kontrol';
}
