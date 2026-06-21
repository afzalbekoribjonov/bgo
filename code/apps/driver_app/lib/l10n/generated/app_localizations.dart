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
  /// **'Beshariq Haydovchi'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchi kirishi'**
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

  /// No description provided for @online.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In uz, this message translates to:
  /// **'Oflayn'**
  String get offline;

  /// No description provided for @offlineHint.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarni ko\'rish uchun onlayn bo\'ling'**
  String get offlineHint;

  /// No description provided for @availableTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud buyurtmalar'**
  String get availableTitle;

  /// No description provided for @myDeliveriesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mening yetkazishlarim'**
  String get myDeliveriesTitle;

  /// No description provided for @noAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha buyurtma yo\'q'**
  String get noAvailable;

  /// No description provided for @noDeliveries.
  ///
  /// In uz, this message translates to:
  /// **'Faol yetkazish yo\'q'**
  String get noDeliveries;

  /// No description provided for @accept.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilish'**
  String get accept;

  /// No description provided for @markPicked.
  ///
  /// In uz, this message translates to:
  /// **'Oldim'**
  String get markPicked;

  /// No description provided for @markDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazdim'**
  String get markDelivered;

  /// No description provided for @deliverTo.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get deliverTo;

  /// No description provided for @orderNo.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma #{no}'**
  String orderNo(String no);

  /// No description provided for @priceSom.
  ///
  /// In uz, this message translates to:
  /// **'{amount} so\'m'**
  String priceSom(String amount);

  /// No description provided for @statusAssigned.
  ///
  /// In uz, this message translates to:
  /// **'Sizga biriktirildi'**
  String get statusAssigned;

  /// No description provided for @statusPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lda'**
  String get statusPickedUp;

  /// No description provided for @earningsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Daromadim'**
  String get earningsTitle;

  /// No description provided for @earningsToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get earningsToday;

  /// No description provided for @earningsTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get earningsTotal;

  /// No description provided for @deliveriesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta yetkazish'**
  String deliveriesCount(int count);

  /// No description provided for @yourEarning.
  ///
  /// In uz, this message translates to:
  /// **'Daromad'**
  String get yourEarning;

  /// No description provided for @deliveryTab.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish'**
  String get deliveryTab;

  /// No description provided for @taxiTab.
  ///
  /// In uz, this message translates to:
  /// **'Taksi'**
  String get taxiTab;

  /// No description provided for @taxiAvailableTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud safarlar'**
  String get taxiAvailableTitle;

  /// No description provided for @taxiMyTripsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mening safarlarim'**
  String get taxiMyTripsTitle;

  /// No description provided for @taxiNoAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha safar yo\'q'**
  String get taxiNoAvailable;

  /// No description provided for @taxiNoActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol safar yo\'q'**
  String get taxiNoActive;

  /// No description provided for @taxiStart.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lovchini oldim'**
  String get taxiStart;

  /// No description provided for @taxiComplete.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlash'**
  String get taxiComplete;

  /// No description provided for @taxiTripNo.
  ///
  /// In uz, this message translates to:
  /// **'Safar #{no}'**
  String taxiTripNo(String no);

  /// No description provided for @taxiKm.
  ///
  /// In uz, this message translates to:
  /// **'{km} km'**
  String taxiKm(String km);

  /// No description provided for @taxiStatusAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilindi'**
  String get taxiStatusAccepted;

  /// No description provided for @taxiStatusInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lda'**
  String get taxiStatusInProgress;

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

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;
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
