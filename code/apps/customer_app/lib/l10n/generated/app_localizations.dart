import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('uz'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')
  ];

  /// No description provided for @appName.
  ///
  /// In uz, this message translates to:
  /// **'Beshariq'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz!'**
  String get welcome;

  /// No description provided for @chooseService.
  ///
  /// In uz, this message translates to:
  /// **'Xizmatni tanlang'**
  String get chooseService;

  /// No description provided for @serviceFood.
  ///
  /// In uz, this message translates to:
  /// **'Ovqat'**
  String get serviceFood;

  /// No description provided for @serviceTaxi.
  ///
  /// In uz, this message translates to:
  /// **'Taksi'**
  String get serviceTaxi;

  /// No description provided for @serviceDelivery.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka'**
  String get serviceDelivery;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @loginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kirish / Ro\'yxatdan o\'tish'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun telefon raqamingizni kiriting'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get phoneLabel;

  /// No description provided for @sendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuborish'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodi'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga yuborilgan kodni kiriting'**
  String otpSubtitle(String phone);

  /// No description provided for @otpLabel.
  ///
  /// In uz, this message translates to:
  /// **'Kod'**
  String get otpLabel;

  /// No description provided for @verify.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get resendCode;

  /// No description provided for @devCodeHint.
  ///
  /// In uz, this message translates to:
  /// **'Sinov rejimi — kod: {code}'**
  String devCodeHint(String code);

  /// No description provided for @consentTitle.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik va shartlar'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish orqali siz Foydalanish shartlari va Maxfiylik siyosatiga rozilik bildirasiz. Joylashuv ma\'lumotlari xizmat ko\'rsatish uchun ishlatiladi.'**
  String get consentBody;

  /// No description provided for @consentCheckbox.
  ///
  /// In uz, this message translates to:
  /// **'Men shartlar va maxfiylik siyosatiga roziman'**
  String get consentCheckbox;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueButton;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami noto\'g\'ri (+998XXXXXXXXX)'**
  String get errorInvalidPhone;

  /// No description provided for @errorInvalidCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod noto\'g\'ri yoki muddati tugagan'**
  String get errorInvalidCode;

  /// No description provided for @errorGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi. Qayta urinib ko\'ring.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasi yo\'q'**
  String get errorNetwork;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz': {
  switch (locale.scriptCode) {
    case 'Cyrl': return AppLocalizationsUzCyrl();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru': return AppLocalizationsRu();
    case 'uz': return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
