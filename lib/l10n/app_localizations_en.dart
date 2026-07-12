// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyGaraj';

  @override
  String get navMyCars => 'My vehicles';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get unitsLabel => 'Units';

  @override
  String get unitsMetric => 'Metric (km)';

  @override
  String get unitsImperial => 'Imperial (mi)';

  @override
  String get unitKmShort => 'km';

  @override
  String get unitMilesShort => 'mi';

  @override
  String get distanceLabelKm => 'Kilometres';

  @override
  String get distanceLabelMi => 'Miles';

  @override
  String get distanceHintKm => 'e.g. 145000 or 145,000';

  @override
  String get distanceHintMi => 'e.g. 90000';

  @override
  String get distanceRequiredKm => 'Kilometres required';

  @override
  String get distanceRequiredMi => 'Miles required';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutSubtitle =>
      'Signs out on this device; vehicle data is not deleted.';

  @override
  String get signOutDialogTitle => 'Sign out';

  @override
  String get signOutConfirm => 'Do you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Notifications are sent 15, 7, and 1 day before the reminder.';

  @override
  String get versionLabel => 'Version';

  @override
  String get emptyGarageTitle => 'Welcome to your garage';

  @override
  String get emptyGarageSubtitle =>
      'Add your vehicles, track insurance, inspection and maintenance dates in one place.';

  @override
  String get addFirstCar => 'Add your first vehicle';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get maintenanceHistory => 'Maintenance history';

  @override
  String get maintenanceHistorySubtitle => 'View all service work performed';

  @override
  String get seeAll => 'See all';

  @override
  String get noMaintenanceYet => 'No maintenance records yet';

  @override
  String get noMaintenanceHint => 'Tap + to add oil change, tires, etc.';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get newCar => 'New vehicle';

  @override
  String get statMaintenanceCost => 'Maintenance cost';

  @override
  String get statLastService => 'Last service';

  @override
  String get statTotal => 'Total';

  @override
  String get today => 'Today';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String monthsCount(int months) {
    return '$months months';
  }

  @override
  String yearsCount(int years) {
    return '$years years';
  }

  @override
  String get allUpToDate => 'Reminders';

  @override
  String get noUpcomingReminders => 'No upcoming reminders';

  @override
  String get add => 'Add';

  @override
  String get addNew => 'Add new';

  @override
  String get expired => 'Expired';

  @override
  String get remainingUntilExpiry => 'Remaining until expiry';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String monthsAgo(int months) {
    return '$months months ago';
  }

  @override
  String get flagOfficialShort => 'Official';

  @override
  String get flagWarrantyShort => 'Warranty';

  @override
  String get flagReceiptShort => 'Receipt';

  @override
  String get flagInsuranceShort => 'Insurance';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get allRemindersEmpty =>
      'No reminders yet. Open a vehicle and add insurance, inspection or emissions dates.';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get welcomeTitle => 'Your garage, all in one place';

  @override
  String get welcomeSubtitle =>
      'Track maintenance, mileage and reminders for every car you own.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeSwipeHint => 'Swipe to enter';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Welcome back — pick up right where you left off.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get loginIdLabel => 'Email or username';

  @override
  String get loginIdRequired => 'Email or username is required';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameInvalid =>
      'Username: 3–32 chars, lowercase letters, numbers, underscore';

  @override
  String get usernameTaken => 'This username is already taken';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String get passwordMinLength => 'At least 6 characters';

  @override
  String get signInButton => 'Sign in';

  @override
  String get noAccountQuestion => 'Don\'t have an account?';

  @override
  String get registerLink => 'Sign up';

  @override
  String get loginFooterNote =>
      'Your password is only sent when signing in and is verified through Supabase.';

  @override
  String get registerAppBarTitle => 'Sign up';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Create your account in a few seconds.';

  @override
  String get displayNameLabel => 'Full name (optional)';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registerButton => 'Sign up';

  @override
  String get alreadyHaveAccountSignIn => 'I already have an account — sign in';

  @override
  String get registerFooterNote =>
      'Your registration password is only used for verification and is not stored on the device.';

  @override
  String get transmissionManual => 'Manual';

  @override
  String get transmissionAutomatic => 'Automatic';

  @override
  String get transmissionSemiAutomatic => 'Semi-automatic';

  @override
  String get transmissionCvt => 'CVT';

  @override
  String get fuelPetrol => 'Gasoline';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelLpg => 'LPG';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get fuelPlugInHybrid => 'Plug-in hybrid';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get deleteCarTitle => 'Delete vehicle';

  @override
  String deleteCarMessage(String brand, String model) {
    return 'The $brand $model record and related maintenance/reminders will be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get carDeleted => 'Vehicle deleted';

  @override
  String deleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get cropPhotoTitle => 'Crop photo';

  @override
  String get cropTitle => 'Crop';

  @override
  String get cropPluginMissing =>
      'Cropping is not loaded yet. Fully quit and restart the app. Using the photo without cropping for now.';

  @override
  String cropSkipped(String error) {
    return 'Cropping skipped: $error';
  }

  @override
  String photoPickFailed(String error) {
    return 'Could not select photo: $error';
  }

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get recrop => 'Crop again';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get yearNotSelected => 'Year not selected';

  @override
  String get transmissionNotSelected => 'Transmission type not selected';

  @override
  String get fuelNotSelected => 'Fuel type not selected';

  @override
  String get removingBackground => 'Removing background…';

  @override
  String get backgroundRemovalFailed =>
      'Background could not be removed; original photo was used.';

  @override
  String get carUpdated => 'Vehicle updated';

  @override
  String get carAdded => 'Vehicle added';

  @override
  String get backgroundPreviewFailed =>
      'Could not create background preview; showing original photo.';

  @override
  String get editCarTitle => 'Edit vehicle';

  @override
  String get newCarTitle => 'New vehicle';

  @override
  String get deleteCarTooltip => 'Delete vehicle';

  @override
  String get cardColorLabel => 'Card color';

  @override
  String get cardColorAuto => 'Automatic';

  @override
  String get autoRemoveBackground => 'Automatically remove background';

  @override
  String get plateLabel => 'License plate';

  @override
  String get plateHint => '34 ABC 1234';

  @override
  String get plateRequired => 'License plate is required';

  @override
  String get plateForbiddenLetters =>
      'Letters Ç, Ş, İ, Ö, Ü, Ğ are not used; e.g. 34 ABC 1234';

  @override
  String get plateInvalidFormat =>
      'Province 01-81, 1-3 letters (no ÇŞİÖÜĞ), digits: 1 letter→4; 2 letters→3-4; 3 letters→2-3';

  @override
  String get brandLabel => 'Brand';

  @override
  String get selectBrand => 'Select brand';

  @override
  String get customBrandLabel => 'Brand name';

  @override
  String get customBrandHint => 'Full brand name';

  @override
  String get customBrandRequired => 'Brand name is required';

  @override
  String get modelLabel => 'Model';

  @override
  String get selectModel => 'Select model';

  @override
  String get customModelLabel => 'Model name';

  @override
  String get customModelHint => 'Full model name';

  @override
  String get customModelRequired => 'Model name is required';

  @override
  String get yearLabel => 'Year';

  @override
  String get selectYear => 'Select year';

  @override
  String get mileageLabel => 'Mileage';

  @override
  String get mileageHint => 'e.g. 145000 or 145,000';

  @override
  String get mileageInvalid => 'Enter valid mileage';

  @override
  String get transmissionLabel => 'Transmission type';

  @override
  String get selectTransmission => 'Select transmission';

  @override
  String get fuelTypeLabel => 'Fuel type';

  @override
  String get selectFuel => 'Select fuel';

  @override
  String get updateButton => 'Update';

  @override
  String get saveButton => 'Save';

  @override
  String get catalogOther => 'Other';

  @override
  String get officialService => 'Official service';

  @override
  String get warranty => 'Warranty';

  @override
  String get insurance => 'Insurance';

  @override
  String get invoiceReceipt => 'Invoice/receipt';

  @override
  String get maintenanceLogTitle => 'Maintenance log';

  @override
  String get addMaintenance => 'Add maintenance';

  @override
  String get maintenanceEmpty =>
      'No maintenance records yet.\nTap + to add the first one.';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get totalSpending => 'Total spending';

  @override
  String get recordsCount => 'records';

  @override
  String get newMaintenanceEntry => 'New maintenance entry';

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get titleHint => 'If left empty, built from your selections below';

  @override
  String get titleOrItemsRequired => 'Enter a title or select items below';

  @override
  String get dateLabel => 'Date';

  @override
  String get kmLabel => 'KM';

  @override
  String get kmRequired => 'KM is required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get costLabel => 'Cost';

  @override
  String get optional => 'Optional';

  @override
  String get costRequired => 'Cost is required';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get costOptionalWithWarranty =>
      'If warranty or insurance is selected, you can leave the amount empty or 0.';

  @override
  String get additionalInfo => 'Additional info';

  @override
  String get serviceShopLabel => 'Service shop or mechanic (optional)';

  @override
  String get workPerformed => 'Work performed';

  @override
  String get searchWorkHint => 'Search work…';

  @override
  String get clear => 'Clear';

  @override
  String get noMatchingWork => 'No work matches your search';

  @override
  String get noItemsSelectedHint =>
      'Nothing selected yet · Scroll inside the box to see all';

  @override
  String itemsSelectedCount(int count) {
    return '$count items selected';
  }

  @override
  String get paymentAndDocuments => 'Payment and documents';

  @override
  String get doneAtAuthorizedService => 'Done at authorized service center';

  @override
  String get underWarranty => 'Covered by warranty';

  @override
  String get invoiceReceived => 'Invoice or receipt received';

  @override
  String get coveredByInsurance => 'Covered by insurance / comprehensive';

  @override
  String get maintenanceLogTooltip => 'Maintenance log';

  @override
  String get remindersEmptyTitle => 'No reminders added yet.';

  @override
  String get remindersEmptySubtitle =>
      'You can add insurance, comprehensive, inspection, or emissions expiry dates.';

  @override
  String deleteReminderMessage(String type) {
    return 'Delete $type reminder?';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get selectExpiryDate => 'Select expiry date';

  @override
  String get expiryDateRequired => 'Please select an expiry date';

  @override
  String get newReminder => 'New reminder';

  @override
  String get editReminder => 'Edit reminder';

  @override
  String reminderTypeAlreadyExists(String type) {
    return '$type is already added for this vehicle.';
  }

  @override
  String get reminderAllTypesExist =>
      'All reminder types are already added for this vehicle.';

  @override
  String get expiryDateLabel => 'Expiry date';

  @override
  String get dateNotSelected => 'No date selected';

  @override
  String get reminderTypeInsurance => 'Insurance';

  @override
  String get reminderTypeComprehensive => 'Comprehensive';

  @override
  String get reminderTypeInspection => 'Inspection';

  @override
  String get reminderTypeEmissions => 'Emissions';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusCritical => 'Critical';

  @override
  String get statusApproaching => 'Approaching';

  @override
  String get statusSafe => 'Safe';

  @override
  String get lastDayToday => 'Last day today';

  @override
  String get lastDayTomorrow => 'Last day tomorrow';

  @override
  String daysRemaining(int days) {
    return '$days days left';
  }

  @override
  String expiredDaysAgo(int days) {
    return 'Expired $days days ago';
  }

  @override
  String get authInvalidEmail => 'Invalid email address.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authUserNotFound => 'No user found with this email.';

  @override
  String get authInvalidCredential =>
      'Sign-in credentials are invalid or expired.';

  @override
  String get authEmailInUse => 'This email is already in use.';

  @override
  String get authWeakPassword => 'Password is too weak; choose a stronger one.';

  @override
  String get authOperationNotAllowed =>
      'This sign-in method is not enabled (Supabase Auth).';

  @override
  String get authNetworkError => 'Network error. Check your connection.';

  @override
  String get authTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String authSignInFailed(String code) {
    return 'Sign-in could not be completed ($code).';
  }

  @override
  String get authEmailConfirmationRequired =>
      'Check your email to confirm your account before signing in.';

  @override
  String get notificationChannelName => 'Vehicle Reminders';

  @override
  String get notificationChannelDescription =>
      'Notifies you when dates like insurance, inspection or emissions are approaching.';

  @override
  String notificationTitle(String type) {
    return '$type reminder';
  }

  @override
  String notificationBody(int days, String type) {
    return '$days days until $type expires.';
  }

  @override
  String notificationBodyWithCar(int days, String type, String car) {
    return '$days days until $type expires for $car.';
  }

  @override
  String get maintOilChange => 'Oil change';

  @override
  String get maintOilFilter => 'Oil filter';

  @override
  String get maintAirFilter => 'Air filter';

  @override
  String get maintCabinFilter => 'Cabin/pollen filter';

  @override
  String get maintFuelFilter => 'Fuel filter';

  @override
  String get maintWaterFilterDiesel => 'Water filter (diesel)';

  @override
  String get maintFrontBrakePads => 'Front brake pads';

  @override
  String get maintRearBrakePads => 'Rear brake pads';

  @override
  String get maintBrakeDisc => 'Brake disc';

  @override
  String get maintBrakeFluid => 'Brake fluid';

  @override
  String get maintTieRodEnds => 'Tie rod ends';

  @override
  String get maintBallJoint => 'Ball joint';

  @override
  String get maintShockAbsorber => 'Shock absorber';

  @override
  String get maintTireChangeRotation => 'Tire change / rotation';

  @override
  String get maintWheelBalance => 'Wheel balancing';

  @override
  String get maintBattery => 'Battery';

  @override
  String get maintSparkPlugsIgnition => 'Spark plugs / ignition';

  @override
  String get maintTimingBeltChain => 'Timing belt / chain set';

  @override
  String get maintClutch => 'Clutch';

  @override
  String get maintCoolantHose => 'Coolant / hose';

  @override
  String get maintAcService => 'A/C gas / service';

  @override
  String get maintExhaustMuffler => 'Exhaust / muffler';

  @override
  String get maintWiper => 'Wiper blades';

  @override
  String get maintHeadlightBulb => 'Headlight / signal bulb';

  @override
  String get maintGeneralInspection => 'General inspection';
}
