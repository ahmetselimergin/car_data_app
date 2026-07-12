// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MyGaraj';

  @override
  String get navMyCars => 'Mis vehículos';

  @override
  String get navReminders => 'Recordatorios';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageTurkish => 'Turco';

  @override
  String get languageSpanish => 'Español';

  @override
  String get unitsLabel => 'Unidades';

  @override
  String get unitsMetric => 'Métrico (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get unitKmShort => 'km';

  @override
  String get unitMilesShort => 'mi';

  @override
  String get distanceLabelKm => 'Kilometraje';

  @override
  String get distanceLabelMi => 'Millas';

  @override
  String get distanceHintKm => 'p. ej. 145000 o 145.000';

  @override
  String get distanceHintMi => 'p. ej. 90000';

  @override
  String get distanceRequiredKm => 'El kilometraje es obligatorio';

  @override
  String get distanceRequiredMi => 'Las millas son obligatorias';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutSubtitle =>
      'Cierra la sesión en este dispositivo; no borra los datos del vehículo.';

  @override
  String get signOutDialogTitle => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Quieres cerrar sesión?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get notificationsLabel => 'Notificaciones';

  @override
  String get notificationsSubtitle =>
      'Se envían notificaciones 15, 7 y 1 día antes del recordatorio.';

  @override
  String get versionLabel => 'Versión';

  @override
  String get emptyGarageTitle => 'Bienvenido a tu garaje';

  @override
  String get emptyGarageSubtitle =>
      'Añade tus vehículos, controla fechas de seguro, inspección y mantenimiento en un solo lugar.';

  @override
  String get addFirstCar => 'Añade tu primer vehículo';

  @override
  String get needsAttention => 'Requiere atención';

  @override
  String get maintenanceHistory => 'Historial de mantenimiento';

  @override
  String get maintenanceHistorySubtitle => 'Ver todos los servicios realizados';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get noMaintenanceYet => 'Aún no hay registros de mantenimiento';

  @override
  String get noMaintenanceHint =>
      'Pulsa + para añadir cambio de aceite, neumáticos, etc.';

  @override
  String get addReminder => 'Añadir recordatorio';

  @override
  String get newCar => 'Vehículo nuevo';

  @override
  String get statMaintenanceCost => 'Coste de mantenimiento';

  @override
  String get statLastService => 'Último servicio';

  @override
  String get statTotal => 'Total';

  @override
  String get today => 'Hoy';

  @override
  String daysCount(int days) {
    return '$days días';
  }

  @override
  String monthsCount(int months) {
    return '$months meses';
  }

  @override
  String yearsCount(int years) {
    return '$years años';
  }

  @override
  String get allUpToDate => 'Todo al día';

  @override
  String get noUpcomingReminders =>
      'No hay recordatorios próximos para este vehículo.';

  @override
  String get add => 'Añadir';

  @override
  String get addNew => 'Añadir nuevo';

  @override
  String get expired => 'Caducado';

  @override
  String get remainingUntilExpiry => 'Restante hasta vencimiento';

  @override
  String daysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String weeksAgo(int weeks) {
    return 'hace $weeks semanas';
  }

  @override
  String monthsAgo(int months) {
    return 'hace $months meses';
  }

  @override
  String get flagOfficialShort => 'Oficial';

  @override
  String get flagWarrantyShort => 'Garantía';

  @override
  String get flagReceiptShort => 'Ticket';

  @override
  String get flagInsuranceShort => 'Seguro';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get allRemindersEmpty =>
      'Aún no hay recordatorios. Abre un vehículo y añade fechas de seguro, inspección o emisiones.';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get welcomeTitle => 'Tu garaje, todo en un solo lugar';

  @override
  String get welcomeSubtitle =>
      'Controla el mantenimiento, el kilometraje y los recordatorios de todos tus coches.';

  @override
  String get welcomeGetStarted => 'Empezar';

  @override
  String get welcomeSwipeHint => 'Desliza para entrar';

  @override
  String get welcomeCreateAccount => 'Crear una cuenta';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle => 'Bienvenido de nuevo: continúa donde lo dejaste.';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailRequired => 'El correo es obligatorio';

  @override
  String get loginIdLabel => 'Correo o usuario';

  @override
  String get loginIdRequired => 'Correo o usuario obligatorio';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get usernameRequired => 'El usuario es obligatorio';

  @override
  String get usernameInvalid =>
      'Usuario: 3–32 caracteres, minúsculas, números, guion bajo';

  @override
  String get usernameTaken => 'Este nombre de usuario ya está en uso';

  @override
  String get emailInvalid => 'Introduce un correo válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get showPassword => 'Mostrar';

  @override
  String get hidePassword => 'Ocultar';

  @override
  String get passwordMinLength => 'Al menos 6 caracteres';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get noAccountQuestion => '¿No tienes cuenta?';

  @override
  String get registerLink => 'Regístrate';

  @override
  String get loginFooterNote =>
      'La contraseña solo se envía al iniciar sesión y se verifica mediante Supabase.';

  @override
  String get registerAppBarTitle => 'Registrarse';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubtitle => 'Crea tu cuenta en unos segundos.';

  @override
  String get displayNameLabel => 'Nombre completo (opcional)';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get alreadyHaveAccountSignIn => 'Ya tengo cuenta — iniciar sesión';

  @override
  String get registerFooterNote =>
      'La contraseña de registro solo se usa para verificación y no se guarda en el dispositivo.';

  @override
  String get transmissionManual => 'Manual';

  @override
  String get transmissionAutomatic => 'Automático';

  @override
  String get transmissionSemiAutomatic => 'Semiautomático';

  @override
  String get transmissionCvt => 'CVT';

  @override
  String get fuelPetrol => 'Gasolina';

  @override
  String get fuelDiesel => 'Diésel';

  @override
  String get fuelLpg => 'GLP';

  @override
  String get fuelHybrid => 'Híbrido';

  @override
  String get fuelPlugInHybrid => 'Híbrido enchufable';

  @override
  String get fuelElectric => 'Eléctrico';

  @override
  String get deleteCarTitle => 'Eliminar vehículo';

  @override
  String deleteCarMessage(String brand, String model) {
    return 'Se eliminará el registro de $brand $model y el mantenimiento/recordatorios asociados.';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get carDeleted => 'Vehículo eliminado';

  @override
  String deleteFailed(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get cropPhotoTitle => 'Recortar foto';

  @override
  String get cropTitle => 'Recortar';

  @override
  String get cropPluginMissing =>
      'El recorte aún no está cargado. Cierra la app por completo y reiníciala. Por ahora se usa la foto sin recortar.';

  @override
  String cropSkipped(String error) {
    return 'Recorte omitido: $error';
  }

  @override
  String photoPickFailed(String error) {
    return 'No se pudo seleccionar la foto: $error';
  }

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Elegir de la galería';

  @override
  String get recrop => 'Volver a recortar';

  @override
  String get removePhoto => 'Quitar foto';

  @override
  String get yearNotSelected => 'Año no seleccionado';

  @override
  String get transmissionNotSelected => 'Tipo de transmisión no seleccionado';

  @override
  String get fuelNotSelected => 'Tipo de combustible no seleccionado';

  @override
  String get removingBackground => 'Eliminando fondo…';

  @override
  String get backgroundRemovalFailed =>
      'No se pudo quitar el fondo; se usó la foto original.';

  @override
  String get carUpdated => 'Vehículo actualizado';

  @override
  String get carAdded => 'Vehículo añadido';

  @override
  String get backgroundPreviewFailed =>
      'No se pudo crear la vista previa del fondo; se muestra la foto original.';

  @override
  String get editCarTitle => 'Editar vehículo';

  @override
  String get newCarTitle => 'Vehículo nuevo';

  @override
  String get deleteCarTooltip => 'Eliminar vehículo';

  @override
  String get cardColorLabel => 'Color de tarjeta';

  @override
  String get cardColorAuto => 'Automático';

  @override
  String get autoRemoveBackground => 'Quitar fondo automáticamente';

  @override
  String get plateLabel => 'Matrícula';

  @override
  String get plateHint => '34 ABC 1234';

  @override
  String get plateRequired => 'La matrícula es obligatoria';

  @override
  String get plateForbiddenLetters =>
      'No se usan Ç, Ş, İ, Ö, Ü, Ğ; p. ej. 34 ABC 1234';

  @override
  String get plateInvalidFormat =>
      'Provincia 01-81, 1-3 letras (sin ÇŞİÖÜĞ), dígitos: 1 letra→4; 2 letras→3-4; 3 letras→2-3';

  @override
  String get brandLabel => 'Marca';

  @override
  String get selectBrand => 'Selecciona marca';

  @override
  String get customBrandLabel => 'Nombre de marca';

  @override
  String get customBrandHint => 'Nombre completo de la marca';

  @override
  String get customBrandRequired => 'El nombre de marca es obligatorio';

  @override
  String get modelLabel => 'Modelo';

  @override
  String get selectModel => 'Selecciona modelo';

  @override
  String get customModelLabel => 'Nombre del modelo';

  @override
  String get customModelHint => 'Nombre completo del modelo';

  @override
  String get customModelRequired => 'El nombre del modelo es obligatorio';

  @override
  String get yearLabel => 'Año';

  @override
  String get selectYear => 'Selecciona año';

  @override
  String get mileageLabel => 'Kilometraje';

  @override
  String get mileageHint => 'p. ej. 145000 o 145.000';

  @override
  String get mileageInvalid => 'Introduce un kilometraje válido';

  @override
  String get transmissionLabel => 'Tipo de transmisión';

  @override
  String get selectTransmission => 'Selecciona transmisión';

  @override
  String get fuelTypeLabel => 'Tipo de combustible';

  @override
  String get selectFuel => 'Selecciona combustible';

  @override
  String get updateButton => 'Actualizar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get catalogOther => 'Otro';

  @override
  String get officialService => 'Servicio oficial';

  @override
  String get warranty => 'Garantía';

  @override
  String get insurance => 'Seguro';

  @override
  String get invoiceReceipt => 'Factura/ticket';

  @override
  String get maintenanceLogTitle => 'Registro de mantenimiento';

  @override
  String get addMaintenance => 'Añadir mantenimiento';

  @override
  String get maintenanceEmpty =>
      'Aún no hay registros de mantenimiento.\nPulsa + para añadir el primero.';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get totalSpending => 'Gasto total';

  @override
  String get recordsCount => 'registros';

  @override
  String get newMaintenanceEntry => 'Nuevo registro de mantenimiento';

  @override
  String get titleOptional => 'Título (opcional)';

  @override
  String get titleHint =>
      'Si lo dejas vacío, se genera a partir de tus selecciones';

  @override
  String get titleOrItemsRequired =>
      'Escribe un título o selecciona ítems abajo';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get kmLabel => 'KM';

  @override
  String get kmRequired => 'El KM es obligatorio';

  @override
  String get enterValidNumber => 'Introduce un número válido';

  @override
  String get costLabel => 'Coste';

  @override
  String get optional => 'Opcional';

  @override
  String get costRequired => 'El coste es obligatorio';

  @override
  String get enterValidAmount => 'Introduce un importe válido';

  @override
  String get costOptionalWithWarranty =>
      'Si hay garantía o seguro, puedes dejar el importe vacío o en 0.';

  @override
  String get additionalInfo => 'Información adicional';

  @override
  String get serviceShopLabel => 'Taller o mecánico (opcional)';

  @override
  String get workPerformed => 'Trabajos realizados';

  @override
  String get searchWorkHint => 'Buscar trabajo…';

  @override
  String get clear => 'Borrar';

  @override
  String get noMatchingWork => 'Ningún trabajo coincide con tu búsqueda';

  @override
  String get noItemsSelectedHint =>
      'Nada seleccionado · Desplázate en el recuadro para ver todo';

  @override
  String itemsSelectedCount(int count) {
    return '$count ítems seleccionados';
  }

  @override
  String get paymentAndDocuments => 'Pago y documentos';

  @override
  String get doneAtAuthorizedService =>
      'Realizado en servicio oficial autorizado';

  @override
  String get underWarranty => 'Cubierto por garantía';

  @override
  String get invoiceReceived => 'Factura o ticket recibido';

  @override
  String get coveredByInsurance => 'Cubierto por seguro / todo riesgo';

  @override
  String get maintenanceLogTooltip => 'Registro de mantenimiento';

  @override
  String get remindersEmptyTitle => 'Aún no hay recordatorios.';

  @override
  String get remindersEmptySubtitle =>
      'Puedes añadir fechas de seguro, todo riesgo, inspección o emisiones.';

  @override
  String deleteReminderMessage(String type) {
    return '¿Eliminar recordatorio de $type?';
  }

  @override
  String get dismiss => 'Descartar';

  @override
  String get selectExpiryDate => 'Seleccionar fecha de vencimiento';

  @override
  String get expiryDateRequired => 'Selecciona una fecha de vencimiento';

  @override
  String get newReminder => 'Nuevo recordatorio';

  @override
  String get editReminder => 'Editar recordatorio';

  @override
  String reminderTypeAlreadyExists(String type) {
    return '$type ya está añadido para este vehículo.';
  }

  @override
  String get reminderAllTypesExist =>
      'Ya están añadidos todos los tipos de recordatorio para este vehículo.';

  @override
  String get expiryDateLabel => 'Fecha de vencimiento';

  @override
  String get dateNotSelected => 'Fecha no seleccionada';

  @override
  String get reminderTypeInsurance => 'Seguro';

  @override
  String get reminderTypeComprehensive => 'Todo riesgo';

  @override
  String get reminderTypeInspection => 'Inspección';

  @override
  String get reminderTypeEmissions => 'Emisiones';

  @override
  String get statusExpired => 'Caducado';

  @override
  String get statusCritical => 'Crítico';

  @override
  String get statusApproaching => 'Próximo';

  @override
  String get statusSafe => 'Seguro';

  @override
  String get lastDayToday => 'Último día hoy';

  @override
  String get lastDayTomorrow => 'Último día mañana';

  @override
  String daysRemaining(int days) {
    return 'Quedan $days días';
  }

  @override
  String expiredDaysAgo(int days) {
    return 'Caducó hace $days días';
  }

  @override
  String get authInvalidEmail => 'Dirección de correo no válida.';

  @override
  String get authUserDisabled => 'Esta cuenta ha sido deshabilitada.';

  @override
  String get authUserNotFound => 'No se encontró usuario con este correo.';

  @override
  String get authInvalidCredential =>
      'Las credenciales son inválidas o han caducado.';

  @override
  String get authEmailInUse => 'Este correo ya está en uso.';

  @override
  String get authWeakPassword =>
      'Contraseña demasiado débil; elige una más fuerte.';

  @override
  String get authOperationNotAllowed =>
      'Este método de acceso no está habilitado (Supabase Auth).';

  @override
  String get authNetworkError => 'Error de red. Comprueba tu conexión.';

  @override
  String get authTooManyRequests => 'Demasiados intentos. Inténtalo más tarde.';

  @override
  String authSignInFailed(String code) {
    return 'No se pudo completar el inicio de sesión ($code).';
  }

  @override
  String get authEmailConfirmationRequired =>
      'Confirma tu correo electrónico antes de iniciar sesión.';

  @override
  String get notificationChannelName => 'Recordatorios del vehículo';

  @override
  String get notificationChannelDescription =>
      'Te avisa cuando se acercan fechas como seguro, inspección o emisiones.';

  @override
  String notificationTitle(String type) {
    return 'Recordatorio de $type';
  }

  @override
  String notificationBody(int days, String type) {
    return 'Quedan $days días para el vencimiento de $type.';
  }

  @override
  String notificationBodyWithCar(int days, String type, String car) {
    return 'Quedan $days días para el vencimiento de $type de $car.';
  }

  @override
  String get maintOilChange => 'Cambio de aceite';

  @override
  String get maintOilFilter => 'Filtro de aceite';

  @override
  String get maintAirFilter => 'Filtro de aire';

  @override
  String get maintCabinFilter => 'Filtro de habitáculo';

  @override
  String get maintFuelFilter => 'Filtro de combustible';

  @override
  String get maintWaterFilterDiesel => 'Filtro de agua (diésel)';

  @override
  String get maintFrontBrakePads => 'Pastillas de freno delanteras';

  @override
  String get maintRearBrakePads => 'Pastillas de freno traseras';

  @override
  String get maintBrakeDisc => 'Disco de freno';

  @override
  String get maintBrakeFluid => 'Líquido de frenos';

  @override
  String get maintTieRodEnds => 'Rótulas de dirección';

  @override
  String get maintBallJoint => 'Rótula';

  @override
  String get maintShockAbsorber => 'Amortiguador';

  @override
  String get maintTireChangeRotation => 'Cambio / rotación de neumáticos';

  @override
  String get maintWheelBalance => 'Balanceo de ruedas';

  @override
  String get maintBattery => 'Batería';

  @override
  String get maintSparkPlugsIgnition => 'Bujías / encendido';

  @override
  String get maintTimingBeltChain => 'Kit de distribución / cadena';

  @override
  String get maintClutch => 'Embrague';

  @override
  String get maintCoolantHose => 'Refrigerante / manguera';

  @override
  String get maintAcService => 'Gas / servicio de A/A';

  @override
  String get maintExhaustMuffler => 'Escape / silenciador';

  @override
  String get maintWiper => 'Limpiaparabrisas';

  @override
  String get maintHeadlightBulb => 'Bombilla de faro / intermitente';

  @override
  String get maintGeneralInspection => 'Revisión general';
}
