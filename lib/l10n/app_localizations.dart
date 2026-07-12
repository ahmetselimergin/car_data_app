import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyGaraj'**
  String get appTitle;

  /// No description provided for @navMyCars.
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get navMyCars;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get unitsLabel;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric (km)'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial (mi)'**
  String get unitsImperial;

  /// No description provided for @unitKmShort.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKmShort;

  /// No description provided for @unitMilesShort.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitMilesShort;

  /// No description provided for @distanceLabelKm.
  ///
  /// In en, this message translates to:
  /// **'Kilometres'**
  String get distanceLabelKm;

  /// No description provided for @distanceLabelMi.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get distanceLabelMi;

  /// No description provided for @distanceHintKm.
  ///
  /// In en, this message translates to:
  /// **'e.g. 145000 or 145,000'**
  String get distanceHintKm;

  /// No description provided for @distanceHintMi.
  ///
  /// In en, this message translates to:
  /// **'e.g. 90000'**
  String get distanceHintMi;

  /// No description provided for @distanceRequiredKm.
  ///
  /// In en, this message translates to:
  /// **'Kilometres required'**
  String get distanceRequiredKm;

  /// No description provided for @distanceRequiredMi.
  ///
  /// In en, this message translates to:
  /// **'Miles required'**
  String get distanceRequiredMi;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signs out on this device; vehicle data is not deleted.'**
  String get signOutSubtitle;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutDialogTitle;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are sent 15, 7, and 1 day before the reminder.'**
  String get notificationsSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @emptyGarageTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your garage'**
  String get emptyGarageTitle;

  /// No description provided for @emptyGarageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicles, track insurance, inspection and maintenance dates in one place.'**
  String get emptyGarageSubtitle;

  /// No description provided for @addFirstCar.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle'**
  String get addFirstCar;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @maintenanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Maintenance history'**
  String get maintenanceHistory;

  /// No description provided for @maintenanceHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View all service work performed'**
  String get maintenanceHistorySubtitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noMaintenanceYet.
  ///
  /// In en, this message translates to:
  /// **'No maintenance records yet'**
  String get noMaintenanceYet;

  /// No description provided for @noMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add oil change, tires, etc.'**
  String get noMaintenanceHint;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @newCar.
  ///
  /// In en, this message translates to:
  /// **'New vehicle'**
  String get newCar;

  /// No description provided for @statMaintenanceCost.
  ///
  /// In en, this message translates to:
  /// **'Maintenance cost'**
  String get statMaintenanceCost;

  /// No description provided for @statLastService.
  ///
  /// In en, this message translates to:
  /// **'Last service'**
  String get statLastService;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(int days);

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String monthsCount(int months);

  /// No description provided for @yearsCount.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String yearsCount(int years);

  /// No description provided for @allUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get allUpToDate;

  /// No description provided for @noUpcomingReminders.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders'**
  String get noUpcomingReminders;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @remainingUntilExpiry.
  ///
  /// In en, this message translates to:
  /// **'Remaining until expiry'**
  String get remainingUntilExpiry;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String weeksAgo(int weeks);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String monthsAgo(int months);

  /// No description provided for @flagOfficialShort.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get flagOfficialShort;

  /// No description provided for @flagWarrantyShort.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get flagWarrantyShort;

  /// No description provided for @flagReceiptShort.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get flagReceiptShort;

  /// No description provided for @flagInsuranceShort.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get flagInsuranceShort;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @allRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Open a vehicle and add insurance, inspection or emissions dates.'**
  String get allRemindersEmpty;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your garage, all in one place'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track maintenance, mileage and reminders for every car you own.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe to enter'**
  String get welcomeSwipeHint;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccount;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back — pick up right where you left off.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @loginIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get loginIdLabel;

  /// No description provided for @loginIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or username is required'**
  String get loginIdRequired;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username: 3–32 chars, lowercase letters, numbers, underscore'**
  String get usernameInvalid;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameTaken;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountQuestion;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerLink;

  /// No description provided for @loginFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Your password is only sent when signing in and is verified through Supabase.'**
  String get loginFooterNote;

  /// No description provided for @registerAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerAppBarTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account in a few seconds.'**
  String get registerSubtitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name (optional)'**
  String get displayNameLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerButton;

  /// No description provided for @alreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account — sign in'**
  String get alreadyHaveAccountSignIn;

  /// No description provided for @registerFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Your registration password is only used for verification and is not stored on the device.'**
  String get registerFooterNote;

  /// No description provided for @transmissionManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get transmissionManual;

  /// No description provided for @transmissionAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get transmissionAutomatic;

  /// No description provided for @transmissionSemiAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Semi-automatic'**
  String get transmissionSemiAutomatic;

  /// No description provided for @transmissionCvt.
  ///
  /// In en, this message translates to:
  /// **'CVT'**
  String get transmissionCvt;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Gasoline'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// No description provided for @fuelHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get fuelHybrid;

  /// No description provided for @fuelPlugInHybrid.
  ///
  /// In en, this message translates to:
  /// **'Plug-in hybrid'**
  String get fuelPlugInHybrid;

  /// No description provided for @fuelElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelElectric;

  /// No description provided for @deleteCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get deleteCarTitle;

  /// No description provided for @deleteCarMessage.
  ///
  /// In en, this message translates to:
  /// **'The {brand} {model} record and related maintenance/reminders will be deleted.'**
  String deleteCarMessage(String brand, String model);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @carDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted'**
  String get carDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String deleteFailed(String error);

  /// No description provided for @cropPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get cropPhotoTitle;

  /// No description provided for @cropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropTitle;

  /// No description provided for @cropPluginMissing.
  ///
  /// In en, this message translates to:
  /// **'Cropping is not loaded yet. Fully quit and restart the app. Using the photo without cropping for now.'**
  String get cropPluginMissing;

  /// No description provided for @cropSkipped.
  ///
  /// In en, this message translates to:
  /// **'Cropping skipped: {error}'**
  String cropSkipped(String error);

  /// No description provided for @photoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not select photo: {error}'**
  String photoPickFailed(String error);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @recrop.
  ///
  /// In en, this message translates to:
  /// **'Crop again'**
  String get recrop;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @yearNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Year not selected'**
  String get yearNotSelected;

  /// No description provided for @transmissionNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Transmission type not selected'**
  String get transmissionNotSelected;

  /// No description provided for @fuelNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Fuel type not selected'**
  String get fuelNotSelected;

  /// No description provided for @removingBackground.
  ///
  /// In en, this message translates to:
  /// **'Removing background…'**
  String get removingBackground;

  /// No description provided for @backgroundRemovalFailed.
  ///
  /// In en, this message translates to:
  /// **'Background could not be removed; original photo was used.'**
  String get backgroundRemovalFailed;

  /// No description provided for @carUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated'**
  String get carUpdated;

  /// No description provided for @carAdded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle added'**
  String get carAdded;

  /// No description provided for @backgroundPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create background preview; showing original photo.'**
  String get backgroundPreviewFailed;

  /// No description provided for @editCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editCarTitle;

  /// No description provided for @newCarTitle.
  ///
  /// In en, this message translates to:
  /// **'New vehicle'**
  String get newCarTitle;

  /// No description provided for @deleteCarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get deleteCarTooltip;

  /// No description provided for @cardColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Card color'**
  String get cardColorLabel;

  /// No description provided for @cardColorAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get cardColorAuto;

  /// No description provided for @autoRemoveBackground.
  ///
  /// In en, this message translates to:
  /// **'Automatically remove background'**
  String get autoRemoveBackground;

  /// No description provided for @plateLabel.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get plateLabel;

  /// No description provided for @plateHint.
  ///
  /// In en, this message translates to:
  /// **'34 ABC 1234'**
  String get plateHint;

  /// No description provided for @plateRequired.
  ///
  /// In en, this message translates to:
  /// **'License plate is required'**
  String get plateRequired;

  /// No description provided for @plateForbiddenLetters.
  ///
  /// In en, this message translates to:
  /// **'Letters Ç, Ş, İ, Ö, Ü, Ğ are not used; e.g. 34 ABC 1234'**
  String get plateForbiddenLetters;

  /// No description provided for @plateInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Province 01-81, 1-3 letters (no ÇŞİÖÜĞ), digits: 1 letter→4; 2 letters→3-4; 3 letters→2-3'**
  String get plateInvalidFormat;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @selectBrand.
  ///
  /// In en, this message translates to:
  /// **'Select brand'**
  String get selectBrand;

  /// No description provided for @customBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand name'**
  String get customBrandLabel;

  /// No description provided for @customBrandHint.
  ///
  /// In en, this message translates to:
  /// **'Full brand name'**
  String get customBrandHint;

  /// No description provided for @customBrandRequired.
  ///
  /// In en, this message translates to:
  /// **'Brand name is required'**
  String get customBrandRequired;

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// No description provided for @customModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get customModelLabel;

  /// No description provided for @customModelHint.
  ///
  /// In en, this message translates to:
  /// **'Full model name'**
  String get customModelHint;

  /// No description provided for @customModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Model name is required'**
  String get customModelRequired;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYear;

  /// No description provided for @mileageLabel.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get mileageLabel;

  /// No description provided for @mileageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 145000 or 145,000'**
  String get mileageHint;

  /// No description provided for @mileageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid mileage'**
  String get mileageInvalid;

  /// No description provided for @transmissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Transmission type'**
  String get transmissionLabel;

  /// No description provided for @selectTransmission.
  ///
  /// In en, this message translates to:
  /// **'Select transmission'**
  String get selectTransmission;

  /// No description provided for @fuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelTypeLabel;

  /// No description provided for @selectFuel.
  ///
  /// In en, this message translates to:
  /// **'Select fuel'**
  String get selectFuel;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @catalogOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catalogOther;

  /// No description provided for @officialService.
  ///
  /// In en, this message translates to:
  /// **'Official service'**
  String get officialService;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @invoiceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Invoice/receipt'**
  String get invoiceReceipt;

  /// No description provided for @maintenanceLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance log'**
  String get maintenanceLogTitle;

  /// No description provided for @addMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Add maintenance'**
  String get addMaintenance;

  /// No description provided for @maintenanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No maintenance records yet.\nTap + to add the first one.'**
  String get maintenanceEmpty;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @totalSpending.
  ///
  /// In en, this message translates to:
  /// **'Total spending'**
  String get totalSpending;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get recordsCount;

  /// No description provided for @newMaintenanceEntry.
  ///
  /// In en, this message translates to:
  /// **'New maintenance entry'**
  String get newMaintenanceEntry;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'If left empty, built from your selections below'**
  String get titleHint;

  /// No description provided for @titleOrItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title or select items below'**
  String get titleOrItemsRequired;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @kmLabel.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get kmLabel;

  /// No description provided for @kmRequired.
  ///
  /// In en, this message translates to:
  /// **'KM is required'**
  String get kmRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @costLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costLabel;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @costRequired.
  ///
  /// In en, this message translates to:
  /// **'Cost is required'**
  String get costRequired;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @costOptionalWithWarranty.
  ///
  /// In en, this message translates to:
  /// **'If warranty or insurance is selected, you can leave the amount empty or 0.'**
  String get costOptionalWithWarranty;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional info'**
  String get additionalInfo;

  /// No description provided for @serviceShopLabel.
  ///
  /// In en, this message translates to:
  /// **'Service shop or mechanic (optional)'**
  String get serviceShopLabel;

  /// No description provided for @workPerformed.
  ///
  /// In en, this message translates to:
  /// **'Work performed'**
  String get workPerformed;

  /// No description provided for @searchWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Search work…'**
  String get searchWorkHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noMatchingWork.
  ///
  /// In en, this message translates to:
  /// **'No work matches your search'**
  String get noMatchingWork;

  /// No description provided for @noItemsSelectedHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected yet · Scroll inside the box to see all'**
  String get noItemsSelectedHint;

  /// No description provided for @itemsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String itemsSelectedCount(int count);

  /// No description provided for @paymentAndDocuments.
  ///
  /// In en, this message translates to:
  /// **'Payment and documents'**
  String get paymentAndDocuments;

  /// No description provided for @doneAtAuthorizedService.
  ///
  /// In en, this message translates to:
  /// **'Done at authorized service center'**
  String get doneAtAuthorizedService;

  /// No description provided for @underWarranty.
  ///
  /// In en, this message translates to:
  /// **'Covered by warranty'**
  String get underWarranty;

  /// No description provided for @invoiceReceived.
  ///
  /// In en, this message translates to:
  /// **'Invoice or receipt received'**
  String get invoiceReceived;

  /// No description provided for @coveredByInsurance.
  ///
  /// In en, this message translates to:
  /// **'Covered by insurance / comprehensive'**
  String get coveredByInsurance;

  /// No description provided for @maintenanceLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Maintenance log'**
  String get maintenanceLogTooltip;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders added yet.'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can add insurance, comprehensive, inspection, or emissions expiry dates.'**
  String get remindersEmptySubtitle;

  /// No description provided for @deleteReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {type} reminder?'**
  String deleteReminderMessage(String type);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get selectExpiryDate;

  /// No description provided for @expiryDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an expiry date'**
  String get expiryDateRequired;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @reminderTypeAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'{type} is already added for this vehicle.'**
  String reminderTypeAlreadyExists(String type);

  /// No description provided for @reminderAllTypesExist.
  ///
  /// In en, this message translates to:
  /// **'All reminder types are already added for this vehicle.'**
  String get reminderAllTypesExist;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDateLabel;

  /// No description provided for @dateNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No date selected'**
  String get dateNotSelected;

  /// No description provided for @reminderTypeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get reminderTypeInsurance;

  /// No description provided for @reminderTypeComprehensive.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive'**
  String get reminderTypeComprehensive;

  /// No description provided for @reminderTypeInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get reminderTypeInspection;

  /// No description provided for @reminderTypeEmissions.
  ///
  /// In en, this message translates to:
  /// **'Emissions'**
  String get reminderTypeEmissions;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get statusCritical;

  /// No description provided for @statusApproaching.
  ///
  /// In en, this message translates to:
  /// **'Approaching'**
  String get statusApproaching;

  /// No description provided for @statusSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get statusSafe;

  /// No description provided for @lastDayToday.
  ///
  /// In en, this message translates to:
  /// **'Last day today'**
  String get lastDayToday;

  /// No description provided for @lastDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Last day tomorrow'**
  String get lastDayTomorrow;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysRemaining(int days);

  /// No description provided for @expiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String expiredDaysAgo(int days);

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get authUserNotFound;

  /// No description provided for @authInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Sign-in credentials are invalid or expired.'**
  String get authInvalidCredential;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak; choose a stronger one.'**
  String get authWeakPassword;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled (Supabase Auth).'**
  String get authOperationNotAllowed;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get authNetworkError;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyRequests;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not be completed ({code}).'**
  String authSignInFailed(String code);

  /// No description provided for @authEmailConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account before signing in.'**
  String get authEmailConfirmationRequired;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifies you when dates like insurance, inspection or emissions are approaching.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} reminder'**
  String notificationTitle(String type);

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'{days} days until {type} expires.'**
  String notificationBody(int days, String type);

  /// No description provided for @notificationBodyWithCar.
  ///
  /// In en, this message translates to:
  /// **'{days} days until {type} expires for {car}.'**
  String notificationBodyWithCar(int days, String type, String car);

  /// No description provided for @maintOilChange.
  ///
  /// In en, this message translates to:
  /// **'Oil change'**
  String get maintOilChange;

  /// No description provided for @maintOilFilter.
  ///
  /// In en, this message translates to:
  /// **'Oil filter'**
  String get maintOilFilter;

  /// No description provided for @maintAirFilter.
  ///
  /// In en, this message translates to:
  /// **'Air filter'**
  String get maintAirFilter;

  /// No description provided for @maintCabinFilter.
  ///
  /// In en, this message translates to:
  /// **'Cabin/pollen filter'**
  String get maintCabinFilter;

  /// No description provided for @maintFuelFilter.
  ///
  /// In en, this message translates to:
  /// **'Fuel filter'**
  String get maintFuelFilter;

  /// No description provided for @maintWaterFilterDiesel.
  ///
  /// In en, this message translates to:
  /// **'Water filter (diesel)'**
  String get maintWaterFilterDiesel;

  /// No description provided for @maintFrontBrakePads.
  ///
  /// In en, this message translates to:
  /// **'Front brake pads'**
  String get maintFrontBrakePads;

  /// No description provided for @maintRearBrakePads.
  ///
  /// In en, this message translates to:
  /// **'Rear brake pads'**
  String get maintRearBrakePads;

  /// No description provided for @maintBrakeDisc.
  ///
  /// In en, this message translates to:
  /// **'Brake disc'**
  String get maintBrakeDisc;

  /// No description provided for @maintBrakeFluid.
  ///
  /// In en, this message translates to:
  /// **'Brake fluid'**
  String get maintBrakeFluid;

  /// No description provided for @maintTieRodEnds.
  ///
  /// In en, this message translates to:
  /// **'Tie rod ends'**
  String get maintTieRodEnds;

  /// No description provided for @maintBallJoint.
  ///
  /// In en, this message translates to:
  /// **'Ball joint'**
  String get maintBallJoint;

  /// No description provided for @maintShockAbsorber.
  ///
  /// In en, this message translates to:
  /// **'Shock absorber'**
  String get maintShockAbsorber;

  /// No description provided for @maintTireChangeRotation.
  ///
  /// In en, this message translates to:
  /// **'Tire change / rotation'**
  String get maintTireChangeRotation;

  /// No description provided for @maintWheelBalance.
  ///
  /// In en, this message translates to:
  /// **'Wheel balancing'**
  String get maintWheelBalance;

  /// No description provided for @maintBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get maintBattery;

  /// No description provided for @maintSparkPlugsIgnition.
  ///
  /// In en, this message translates to:
  /// **'Spark plugs / ignition'**
  String get maintSparkPlugsIgnition;

  /// No description provided for @maintTimingBeltChain.
  ///
  /// In en, this message translates to:
  /// **'Timing belt / chain set'**
  String get maintTimingBeltChain;

  /// No description provided for @maintClutch.
  ///
  /// In en, this message translates to:
  /// **'Clutch'**
  String get maintClutch;

  /// No description provided for @maintCoolantHose.
  ///
  /// In en, this message translates to:
  /// **'Coolant / hose'**
  String get maintCoolantHose;

  /// No description provided for @maintAcService.
  ///
  /// In en, this message translates to:
  /// **'A/C gas / service'**
  String get maintAcService;

  /// No description provided for @maintExhaustMuffler.
  ///
  /// In en, this message translates to:
  /// **'Exhaust / muffler'**
  String get maintExhaustMuffler;

  /// No description provided for @maintWiper.
  ///
  /// In en, this message translates to:
  /// **'Wiper blades'**
  String get maintWiper;

  /// No description provided for @maintHeadlightBulb.
  ///
  /// In en, this message translates to:
  /// **'Headlight / signal bulb'**
  String get maintHeadlightBulb;

  /// No description provided for @maintGeneralInspection.
  ///
  /// In en, this message translates to:
  /// **'General inspection'**
  String get maintGeneralInspection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
