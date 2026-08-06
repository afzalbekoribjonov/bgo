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

  /// No description provided for @noInternetConnection.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasi yo\'q'**
  String get noInternetConnection;

  /// No description provided for @homeGpsRequired.
  ///
  /// In uz, this message translates to:
  /// **'Liniyaga chiqish uchun GPS yoqilgan bo\'lishi kerak. Joylashuv ruxsatini tekshiring.'**
  String get homeGpsRequired;

  /// No description provided for @homeReconnecting.
  ///
  /// In uz, this message translates to:
  /// **'Qayta ulanmoqda...'**
  String get homeReconnecting;

  /// No description provided for @homeAddressSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Manzil qidirish...'**
  String get homeAddressSearchHint;

  /// No description provided for @homeAddressPinHint.
  ///
  /// In uz, this message translates to:
  /// **'Xaritada uy manzilingizni belgilang'**
  String get homeAddressPinHint;

  /// No description provided for @homeAddressConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tasdiqlash'**
  String get homeAddressConfirm;

  /// No description provided for @homeAddressUnknownPoint.
  ///
  /// In uz, this message translates to:
  /// **'Belgilangan nuqta'**
  String get homeAddressUnknownPoint;

  /// No description provided for @navTurnLeft.
  ///
  /// In uz, this message translates to:
  /// **'Chapga'**
  String get navTurnLeft;

  /// No description provided for @navTurnRight.
  ///
  /// In uz, this message translates to:
  /// **'O\'ngga'**
  String get navTurnRight;

  /// No description provided for @navTurnSharpLeft.
  ///
  /// In uz, this message translates to:
  /// **'Keskin chapga'**
  String get navTurnSharpLeft;

  /// No description provided for @navTurnSharpRight.
  ///
  /// In uz, this message translates to:
  /// **'Keskin o\'ngga'**
  String get navTurnSharpRight;

  /// No description provided for @navTurnSlightLeft.
  ///
  /// In uz, this message translates to:
  /// **'Bir oz chapga'**
  String get navTurnSlightLeft;

  /// No description provided for @navTurnSlightRight.
  ///
  /// In uz, this message translates to:
  /// **'Bir oz o\'ngga'**
  String get navTurnSlightRight;

  /// No description provided for @navTurnUturn.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga qayting'**
  String get navTurnUturn;

  /// No description provided for @navTurnRoundabout.
  ///
  /// In uz, this message translates to:
  /// **'Aylanma yo\'l'**
  String get navTurnRoundabout;

  /// No description provided for @navTurnBanner.
  ///
  /// In uz, this message translates to:
  /// **'{distance} m dan so\'ng {direction}'**
  String navTurnBanner(int distance, String direction);

  /// No description provided for @navSpeakTurn.
  ///
  /// In uz, this message translates to:
  /// **'{distance} metrdan so\'ng {direction}'**
  String navSpeakTurn(int distance, String direction);

  /// No description provided for @navStraightBanner.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'riga {km} km'**
  String navStraightBanner(int km);

  /// No description provided for @navSpeakStraight.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'riga {km} kilometr'**
  String navSpeakStraight(int km);

  /// No description provided for @navTrafficLightBanner.
  ///
  /// In uz, this message translates to:
  /// **'Svetofor'**
  String get navTrafficLightBanner;

  /// No description provided for @navSpeakTrafficLight.
  ///
  /// In uz, this message translates to:
  /// **'Oldinda nazorat svetofori'**
  String get navSpeakTrafficLight;

  /// No description provided for @homeModeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Uyga rejimi'**
  String get homeModeTitle;

  /// No description provided for @homeModeSetAddressFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval uy manzilini belgilang'**
  String get homeModeSetAddressFirst;

  /// No description provided for @homeModeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Uyga'**
  String get homeModeLabel;

  /// No description provided for @homeModeEditAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni o\'zgartirish'**
  String get homeModeEditAddress;

  /// No description provided for @homeModePoolButton.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'l-yo\'lakay buyurtma olish'**
  String get homeModePoolButton;

  /// No description provided for @homeModeToggleFailed.
  ///
  /// In uz, this message translates to:
  /// **'Rejimni o\'zgartirib bo\'lmadi'**
  String get homeModeToggleFailed;

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

  /// No description provided for @taxiCompleteTitle.
  ///
  /// In uz, this message translates to:
  /// **'Safarni yakunlash'**
  String get taxiCompleteTitle;

  /// No description provided for @taxiDistanceKm.
  ///
  /// In uz, this message translates to:
  /// **'Masofa (km)'**
  String get taxiDistanceKm;

  /// No description provided for @taxiWaitMinutes.
  ///
  /// In uz, this message translates to:
  /// **'Kutish (daqiqa)'**
  String get taxiWaitMinutes;

  /// No description provided for @taxiMeteredBadge.
  ///
  /// In uz, this message translates to:
  /// **'Manzilsiz'**
  String get taxiMeteredBadge;

  /// No description provided for @taxiMeteredFareHint.
  ///
  /// In uz, this message translates to:
  /// **'Narx yakunda hisoblanadi'**
  String get taxiMeteredFareHint;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @chatTitle.
  ///
  /// In uz, this message translates to:
  /// **'Suhbat'**
  String get chatTitle;

  /// No description provided for @chatInputHint.
  ///
  /// In uz, this message translates to:
  /// **'Xabar yozing…'**
  String get chatInputHint;

  /// No description provided for @chatEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hali xabar yo\'q. Suhbatni boshlang.'**
  String get chatEmpty;

  /// No description provided for @chatGreetingNote.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi xabar «Assalomu alaykum,» bilan boshlanadi'**
  String get chatGreetingNote;

  /// No description provided for @chatYou.
  ///
  /// In uz, this message translates to:
  /// **'Siz'**
  String get chatYou;

  /// No description provided for @chatParty.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz'**
  String get chatParty;

  /// No description provided for @supportTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yordam'**
  String get supportTitle;

  /// No description provided for @supportProfileSub.
  ///
  /// In uz, this message translates to:
  /// **'Savollar va tez yordam'**
  String get supportProfileSub;

  /// No description provided for @supportNewRequest.
  ///
  /// In uz, this message translates to:
  /// **'Yangi murojaat'**
  String get supportNewRequest;

  /// No description provided for @supportHistoryEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hali murojaatlar yo\'q'**
  String get supportHistoryEmpty;

  /// No description provided for @supportHistoryEmptySub.
  ///
  /// In uz, this message translates to:
  /// **'Savolingiz bo\'lsa, pastdagi tugma orqali murojaat qiling'**
  String get supportHistoryEmptySub;

  /// No description provided for @supportAiTopic.
  ///
  /// In uz, this message translates to:
  /// **'Erkin suhbat (AI)'**
  String get supportAiTopic;

  /// No description provided for @supportMenuHeadline.
  ///
  /// In uz, this message translates to:
  /// **'Sizga qanday yordam bera olamiz?'**
  String get supportMenuHeadline;

  /// No description provided for @supportMenuSub.
  ///
  /// In uz, this message translates to:
  /// **'Tayyor savollardan birini tanlang yoki AI yordamchiga murojaat qiling'**
  String get supportMenuSub;

  /// No description provided for @supportAskQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Savolim bor'**
  String get supportAskQuestion;

  /// No description provided for @supportInputHint.
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni yozing…'**
  String get supportInputHint;

  /// No description provided for @supportEscalatedBanner.
  ///
  /// In uz, this message translates to:
  /// **'Bu suhbat administratorga yuborildi — tez orada siz bilan bog\'lanishadi.'**
  String get supportEscalatedBanner;

  /// No description provided for @supportStatusOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusEscalated.
  ///
  /// In uz, this message translates to:
  /// **'Adminga yuborilgan'**
  String get supportStatusEscalated;

  /// No description provided for @supportStatusResolved.
  ///
  /// In uz, this message translates to:
  /// **'Yechilgan'**
  String get supportStatusResolved;

  /// No description provided for @supportSenderAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Administrator'**
  String get supportSenderAdmin;

  /// No description provided for @supportSenderAi.
  ///
  /// In uz, this message translates to:
  /// **'AI yordamchi'**
  String get supportSenderAi;

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

  /// No description provided for @parcelTab.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka'**
  String get parcelTab;

  /// No description provided for @parcelAvailableTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud dostavkalar'**
  String get parcelAvailableTitle;

  /// No description provided for @parcelMyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mening dostavkalarim'**
  String get parcelMyTitle;

  /// No description provided for @parcelNoAvailable.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha dostavka yo\'q'**
  String get parcelNoAvailable;

  /// No description provided for @parcelNoActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol dostavka yo\'q'**
  String get parcelNoActive;

  /// No description provided for @parcelNo.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka #{no}'**
  String parcelNo(String no);

  /// No description provided for @parcelStatusPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lda'**
  String get parcelStatusPickedUp;

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

  /// No description provided for @vertFood.
  ///
  /// In uz, this message translates to:
  /// **'Ovqat'**
  String get vertFood;

  /// No description provided for @labelKitchen.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona'**
  String get labelKitchen;

  /// No description provided for @labelCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz'**
  String get labelCustomer;

  /// No description provided for @labelPassenger.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lovchi'**
  String get labelPassenger;

  /// No description provided for @minutesValue.
  ///
  /// In uz, this message translates to:
  /// **'{min} daqiqa'**
  String minutesValue(int min);

  /// No description provided for @cancelReasonVehicle.
  ///
  /// In uz, this message translates to:
  /// **'Mashina bilan bog\'liq muammo'**
  String get cancelReasonVehicle;

  /// No description provided for @cancelReasonTooFar.
  ///
  /// In uz, this message translates to:
  /// **'Masofa juda uzoq'**
  String get cancelReasonTooFar;

  /// No description provided for @cancelReasonCannotReach.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz bilan bog\'lana olmadim'**
  String get cancelReasonCannotReach;

  /// No description provided for @cancelReasonNotAtAddress.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz manzilda topilmadi'**
  String get cancelReasonNotAtAddress;

  /// No description provided for @cancelReasonOther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa sabab'**
  String get cancelReasonOther;

  /// No description provided for @cancelReasonTitleCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish sababi'**
  String get cancelReasonTitleCancel;

  /// No description provided for @cancelReasonTitleDecline.
  ///
  /// In uz, this message translates to:
  /// **'Voz kechish sababi'**
  String get cancelReasonTitleDecline;

  /// No description provided for @cancelReasonHint.
  ///
  /// In uz, this message translates to:
  /// **'Sababni tanlang. Bekor qilish uchun balansingizdan jarima yechiladi.'**
  String get cancelReasonHint;

  /// No description provided for @cancelReasonNoteLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sababni yozing'**
  String get cancelReasonNoteLabel;

  /// No description provided for @cancelReasonSubmitDecline.
  ///
  /// In uz, this message translates to:
  /// **'Voz kechish'**
  String get cancelReasonSubmitDecline;

  /// No description provided for @homeOrderGone.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma endi mavjud emas'**
  String get homeOrderGone;

  /// No description provided for @homeOrderCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma bekor qilindi'**
  String get homeOrderCancelled;

  /// No description provided for @homeNoPhone.
  ///
  /// In uz, this message translates to:
  /// **'Raqam mavjud emas'**
  String get homeNoPhone;

  /// No description provided for @homeDialerFailed.
  ///
  /// In uz, this message translates to:
  /// **'Telefon ilovasi ochilmadi'**
  String get homeDialerFailed;

  /// No description provided for @homeActionFailed.
  ///
  /// In uz, this message translates to:
  /// **'Amalni bajarib bo\'lmadi'**
  String get homeActionFailed;

  /// No description provided for @homeCancelledOfferedToOther.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma boshqa kuryerga taklif qilinadi'**
  String get homeCancelledOfferedToOther;

  /// No description provided for @homeZeroBalance.
  ///
  /// In uz, this message translates to:
  /// **'Balansingiz 0. Liniyaga chiqish uchun hisobni to\'ldiring.'**
  String get homeZeroBalance;

  /// No description provided for @homeGenericError.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik'**
  String get homeGenericError;

  /// No description provided for @driverBlockedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtinchalik bloklangansiz'**
  String get driverBlockedTitle;

  /// No description provided for @driverBlockedNoReason.
  ///
  /// In uz, this message translates to:
  /// **'Administrator sababini ko\'rsatmagan.'**
  String get driverBlockedNoReason;

  /// No description provided for @driverBlockedUntilLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan vaqt'**
  String get driverBlockedUntilLabel;

  /// No description provided for @driverBlockedDaysHours.
  ///
  /// In uz, this message translates to:
  /// **'{days} kun {hours} soat'**
  String driverBlockedDaysHours(int days, int hours);

  /// No description provided for @driverBlockedHoursMinutes.
  ///
  /// In uz, this message translates to:
  /// **'{hours} soat {min} daqiqa'**
  String driverBlockedHoursMinutes(int hours, int min);

  /// No description provided for @driverBlockedOfficeNote.
  ///
  /// In uz, this message translates to:
  /// **'Darhol blokdan chiqish uchun ofisga kelib jarima to\'lang — administrator sizni darhol blokdan chiqaradi.'**
  String get driverBlockedOfficeNote;

  /// No description provided for @driverBlockedClose.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get driverBlockedClose;

  /// No description provided for @homeNewOrder.
  ///
  /// In uz, this message translates to:
  /// **'Yangi buyurtma'**
  String get homeNewOrder;

  /// No description provided for @homeTapToDismiss.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish uchun bosing'**
  String get homeTapToDismiss;

  /// No description provided for @homeDistance.
  ///
  /// In uz, this message translates to:
  /// **'Masofa'**
  String get homeDistance;

  /// No description provided for @homePrice.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get homePrice;

  /// No description provided for @homePickupEarningLine.
  ///
  /// In uz, this message translates to:
  /// **'{pickup} · ulush +{amount} so\'m'**
  String homePickupEarningLine(String pickup, String amount);

  /// No description provided for @homeTakeOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani olish'**
  String get homeTakeOrder;

  /// No description provided for @homeCashPayment.
  ///
  /// In uz, this message translates to:
  /// **'Naqd to\'lov'**
  String get homeCashPayment;

  /// No description provided for @homeCollectFromCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozdan olasiz'**
  String get homeCollectFromCustomer;

  /// No description provided for @homePayKitchen.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonaga to\'laysiz'**
  String get homePayKitchen;

  /// No description provided for @homeYourEarning.
  ///
  /// In uz, this message translates to:
  /// **'Daromadingiz'**
  String get homeYourEarning;

  /// No description provided for @homeServiceFeeBalance.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat haqi (balansdan)'**
  String get homeServiceFeeBalance;

  /// No description provided for @homeOrderNotTaken.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma olinmadi'**
  String get homeOrderNotTaken;

  /// No description provided for @walletTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobim'**
  String get walletTitle;

  /// No description provided for @homeTodayCard.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get homeTodayCard;

  /// No description provided for @homeTodayCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta zakaz'**
  String homeTodayCount(int count);

  /// No description provided for @homeFinishWork.
  ///
  /// In uz, this message translates to:
  /// **'Ishni yakunlash'**
  String get homeFinishWork;

  /// No description provided for @homeGoOnline.
  ///
  /// In uz, this message translates to:
  /// **'Liniyaga chiqish'**
  String get homeGoOnline;

  /// No description provided for @homeKitchenPicked.
  ///
  /// In uz, this message translates to:
  /// **'OSHXONA · OLINDI'**
  String get homeKitchenPicked;

  /// No description provided for @homeKitchenToPickup.
  ///
  /// In uz, this message translates to:
  /// **'OSHXONA · OLIB KETISH'**
  String get homeKitchenToPickup;

  /// No description provided for @homeCustomerAddress.
  ///
  /// In uz, this message translates to:
  /// **'MIJOZ MANZILI'**
  String get homeCustomerAddress;

  /// No description provided for @homeCancelShort.
  ///
  /// In uz, this message translates to:
  /// **'Bekor'**
  String get homeCancelShort;

  /// No description provided for @homePreparingBanner.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonada tayyorlanmoqda — tayyor bo\'lganda oling'**
  String get homePreparingBanner;

  /// No description provided for @actionArrived.
  ///
  /// In uz, this message translates to:
  /// **'Yetib keldim'**
  String get actionArrived;

  /// No description provided for @actionSetOff.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lga chiqish'**
  String get actionSetOff;

  /// No description provided for @actionFinishTrip.
  ///
  /// In uz, this message translates to:
  /// **'Safarni yakunlash'**
  String get actionFinishTrip;

  /// No description provided for @actionPickedOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani oldim'**
  String get actionPickedOrder;

  /// No description provided for @actionDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazildi'**
  String get actionDelivered;

  /// No description provided for @actionPreparing.
  ///
  /// In uz, this message translates to:
  /// **'Tayyorlanmoqda…'**
  String get actionPreparing;

  /// No description provided for @actionPickedParcel.
  ///
  /// In uz, this message translates to:
  /// **'Dastavkani oldim'**
  String get actionPickedParcel;

  /// No description provided for @homeCashToKitchen.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonaga naqd'**
  String get homeCashToKitchen;

  /// No description provided for @homeToSender.
  ///
  /// In uz, this message translates to:
  /// **'Jo\'natuvchigacha'**
  String get homeToSender;

  /// No description provided for @homeRecipientCall.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi · qo\'ng\'iroq'**
  String get homeRecipientCall;

  /// No description provided for @homeRecipient.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi'**
  String get homeRecipient;

  /// No description provided for @homeToCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozgacha'**
  String get homeToCustomer;

  /// No description provided for @homeWaiting.
  ///
  /// In uz, this message translates to:
  /// **'Kutish'**
  String get homeWaiting;

  /// No description provided for @homeStart.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash'**
  String get homeStart;

  /// No description provided for @homeWaitingStop.
  ///
  /// In uz, this message translates to:
  /// **'Kutyapti — to\'xtatish'**
  String get homeWaitingStop;

  /// No description provided for @homePaidWait.
  ///
  /// In uz, this message translates to:
  /// **'Pulli kutish'**
  String get homePaidWait;

  /// No description provided for @homeFreeWait.
  ///
  /// In uz, this message translates to:
  /// **'Bepul kutish'**
  String get homeFreeWait;

  /// No description provided for @statusTaxiAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz oldiga boring'**
  String get statusTaxiAccepted;

  /// No description provided for @statusTaxiArrived.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lovchini kuting'**
  String get statusTaxiArrived;

  /// No description provided for @statusTaxiInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilga yo\'ldasiz'**
  String get statusTaxiInProgress;

  /// No description provided for @statusFoodPending.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona tasdig\'i kutilmoqda'**
  String get statusFoodPending;

  /// No description provided for @statusFoodAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonaga boring · tayyorlanmoqda'**
  String get statusFoodAccepted;

  /// No description provided for @statusFoodReady.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tayyor · oling'**
  String get statusFoodReady;

  /// No description provided for @statusFoodPicked.
  ///
  /// In uz, this message translates to:
  /// **'Mijozga yetkazing'**
  String get statusFoodPicked;

  /// No description provided for @statusParcelAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Jo\'natuvchiga boring'**
  String get statusParcelAccepted;

  /// No description provided for @statusParcelArrived.
  ///
  /// In uz, this message translates to:
  /// **'Posilkani oling'**
  String get statusParcelArrived;

  /// No description provided for @statusParcelPicked.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lga chiqing'**
  String get statusParcelPicked;

  /// No description provided for @statusParcelTransit.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchiga yo\'ldasiz'**
  String get statusParcelTransit;

  /// No description provided for @summaryFoodTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yetkazildi'**
  String get summaryFoodTitle;

  /// No description provided for @summaryTaxiTitle.
  ///
  /// In uz, this message translates to:
  /// **'Safar yakunlandi'**
  String get summaryTaxiTitle;

  /// No description provided for @summaryParcelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka yakunlandi'**
  String get summaryParcelTitle;

  /// No description provided for @sumKitchenCash.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonaga to\'lang (naqd)'**
  String get sumKitchenCash;

  /// No description provided for @sumDeliveryEarning.
  ///
  /// In uz, this message translates to:
  /// **'Daromadingiz (yetkazish)'**
  String get sumDeliveryEarning;

  /// No description provided for @sumTaxiFare.
  ///
  /// In uz, this message translates to:
  /// **'Safar narxi'**
  String get sumTaxiFare;

  /// No description provided for @sumPickupSurcharge.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketish ustamasi'**
  String get sumPickupSurcharge;

  /// No description provided for @sumDistance.
  ///
  /// In uz, this message translates to:
  /// **'Yurilgan masofa'**
  String get sumDistance;

  /// No description provided for @sumTripTime.
  ///
  /// In uz, this message translates to:
  /// **'Safar vaqti'**
  String get sumTripTime;

  /// No description provided for @sumParcelFare.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka narxi'**
  String get sumParcelFare;

  /// No description provided for @sumSize.
  ///
  /// In uz, this message translates to:
  /// **'O\'lcham'**
  String get sumSize;

  /// No description provided for @sumTimeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt'**
  String get sumTimeLabel;

  /// No description provided for @collectFromPassenger.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lovchidan oling'**
  String get collectFromPassenger;

  /// No description provided for @collectFromCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozdan oling'**
  String get collectFromCustomer;

  /// No description provided for @doneButton.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get doneButton;

  /// No description provided for @sizeSmall.
  ///
  /// In uz, this message translates to:
  /// **'Kichik'**
  String get sizeSmall;

  /// No description provided for @sizeLarge.
  ///
  /// In uz, this message translates to:
  /// **'Katta'**
  String get sizeLarge;

  /// No description provided for @sizeMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta'**
  String get sizeMedium;

  /// No description provided for @walletBalancePrefix.
  ///
  /// In uz, this message translates to:
  /// **'Joriy balans'**
  String get walletBalancePrefix;

  /// No description provided for @periodDaily.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik'**
  String get periodDaily;

  /// No description provided for @periodWeekly.
  ///
  /// In uz, this message translates to:
  /// **'Haftalik'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In uz, this message translates to:
  /// **'Oylik'**
  String get periodMonthly;

  /// No description provided for @balanceTopupHistory.
  ///
  /// In uz, this message translates to:
  /// **'To\'ldirish tarixi'**
  String get balanceTopupHistory;

  /// No description provided for @balanceNoTopups.
  ///
  /// In uz, this message translates to:
  /// **'Bu davrda to\'ldirish bo\'lmagan'**
  String get balanceNoTopups;

  /// No description provided for @balanceCurrent.
  ///
  /// In uz, this message translates to:
  /// **'Joriy balans'**
  String get balanceCurrent;

  /// No description provided for @balanceLow.
  ///
  /// In uz, this message translates to:
  /// **'Kam'**
  String get balanceLow;

  /// No description provided for @balanceCanAccept.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarni qabul qilishingiz mumkin'**
  String get balanceCanAccept;

  /// No description provided for @balanceMustTopup.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma olish uchun hisobni to\'ldiring'**
  String get balanceMustTopup;

  /// No description provided for @balanceSupportNote.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni to\'ldirish uchun qo\'llab-quvvatlash xizmatiga murojaat qiling yoki ofisga tashrif buyuring.'**
  String get balanceSupportNote;

  /// No description provided for @msgTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xabarlar'**
  String get msgTitle;

  /// No description provided for @msgRefresh.
  ///
  /// In uz, this message translates to:
  /// **'Yangilash'**
  String get msgRefresh;

  /// No description provided for @msgEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xabar yo\'q'**
  String get msgEmptyTitle;

  /// No description provided for @msgEmptySubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Admin xabarlari shu yerda ko\'rinadi'**
  String get msgEmptySubtitle;

  /// No description provided for @dayToday.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In uz, this message translates to:
  /// **'Kecha'**
  String get dayYesterday;

  /// No description provided for @msgToYou.
  ///
  /// In uz, this message translates to:
  /// **'Sizga'**
  String get msgToYou;

  /// No description provided for @msgAnnouncement.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon'**
  String get msgAnnouncement;

  /// No description provided for @msgNewBadge.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get msgNewBadge;

  /// No description provided for @navDeliverToAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzilga yetkazish'**
  String get navDeliverToAddress;

  /// No description provided for @navGoPickupCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni olib ketishga'**
  String get navGoPickupCustomer;

  /// No description provided for @navEtaChip.
  ///
  /// In uz, this message translates to:
  /// **'~{min} daq · {km} km'**
  String navEtaChip(String min, String km);

  /// No description provided for @poolTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'sh buyurtmalar'**
  String get poolTitle;

  /// No description provided for @poolEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bo\'sh buyurtma yo\'q'**
  String get poolEmpty;

  /// No description provided for @poolLoading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda…'**
  String get poolLoading;

  /// No description provided for @poolTake.
  ///
  /// In uz, this message translates to:
  /// **'Olish'**
  String get poolTake;

  /// No description provided for @tripChatNetworkError.
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq xatosi — xabar yuborilmadi, qayta urining'**
  String get tripChatNetworkError;

  /// No description provided for @tripChatEnded.
  ///
  /// In uz, this message translates to:
  /// **'Bu suhbatga hozir yozib bo\'lmaydi'**
  String get tripChatEnded;

  /// No description provided for @tripChatSendFailed.
  ///
  /// In uz, this message translates to:
  /// **'Xabar yuborilmadi, qayta urining'**
  String get tripChatSendFailed;

  /// No description provided for @tripChatCallTooltip.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroq'**
  String get tripChatCallTooltip;

  /// No description provided for @tripChatConnecting.
  ///
  /// In uz, this message translates to:
  /// **'aloqa kutilmoqda…'**
  String get tripChatConnecting;

  /// No description provided for @tripChatLabel.
  ///
  /// In uz, this message translates to:
  /// **'suhbat'**
  String get tripChatLabel;

  /// No description provided for @tripChatOffline.
  ///
  /// In uz, this message translates to:
  /// **'Internet aloqasi yo\'q — qayta ulanmoqda…'**
  String get tripChatOffline;

  /// No description provided for @tripChatEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hali xabar yo\'q'**
  String get tripChatEmptyTitle;

  /// No description provided for @tripChatEmptySubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi bo\'lib yozing 👋'**
  String get tripChatEmptySubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get profileTitle;

  /// No description provided for @profileAccountSection.
  ///
  /// In uz, this message translates to:
  /// **'Hisob'**
  String get profileAccountSection;

  /// No description provided for @profileMyInfo.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarim'**
  String get profileMyInfo;

  /// No description provided for @profileMyInfoSub.
  ///
  /// In uz, this message translates to:
  /// **'F.I.SH, yosh, telefon'**
  String get profileMyInfoSub;

  /// No description provided for @profileMyCar.
  ///
  /// In uz, this message translates to:
  /// **'Mening mashinam'**
  String get profileMyCar;

  /// No description provided for @profileMyCarSub.
  ///
  /// In uz, this message translates to:
  /// **'Avtomobil va guvohnoma'**
  String get profileMyCarSub;

  /// No description provided for @profileTariffs.
  ///
  /// In uz, this message translates to:
  /// **'Tariflar va daromad'**
  String get profileTariffs;

  /// No description provided for @profileTariffsSub.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi va umumiy daromad'**
  String get profileTariffsSub;

  /// No description provided for @profileSettingsSection.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get profileSettingsSection;

  /// No description provided for @profileSoundLang.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz va til'**
  String get profileSoundLang;

  /// No description provided for @profileSoundLangSub.
  ///
  /// In uz, this message translates to:
  /// **'Signal ovozi, ilova tili'**
  String get profileSoundLangSub;

  /// No description provided for @profileGuide.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'riqnoma'**
  String get profileGuide;

  /// No description provided for @profileGuideSub.
  ///
  /// In uz, this message translates to:
  /// **'Ilovadan qanday foydalanish'**
  String get profileGuideSub;

  /// No description provided for @profileExitApp.
  ///
  /// In uz, this message translates to:
  /// **'Ilovadan chiqish'**
  String get profileExitApp;

  /// No description provided for @profileLogout.
  ///
  /// In uz, this message translates to:
  /// **'Hisobdan chiqish'**
  String get profileLogout;

  /// No description provided for @profileExitHintOnline.
  ///
  /// In uz, this message translates to:
  /// **'Avval «Ishni yakunlash»ni bosing — liniyada turib ilovani yopib bo\'lmaydi.'**
  String get profileExitHintOnline;

  /// No description provided for @profileExitHintActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol buyurtmangiz bor — yakunlamaguncha ilova yopilmaydi.'**
  String get profileExitHintActive;

  /// No description provided for @profileCannotExitOnline.
  ///
  /// In uz, this message translates to:
  /// **'Liniyadasiz — avval ishni yakunlang.'**
  String get profileCannotExitOnline;

  /// No description provided for @profileCannotExitActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol buyurtmangiz bor.'**
  String get profileCannotExitActive;

  /// No description provided for @profileLogoutDialogContent.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingizdan chiqmoqchimisiz? Qayta kirish uchun administrator bergan 8 xonali kod kerak bo\'ladi.'**
  String get profileLogoutDialogContent;

  /// No description provided for @profileYesExit.
  ///
  /// In uz, this message translates to:
  /// **'Ha, chiqish'**
  String get profileYesExit;

  /// No description provided for @profileOnlineBadge.
  ///
  /// In uz, this message translates to:
  /// **'Liniyada'**
  String get profileOnlineBadge;

  /// No description provided for @profileOfflineBadge.
  ///
  /// In uz, this message translates to:
  /// **'Oflayn'**
  String get profileOfflineBadge;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlar'**
  String get profilePersonalInfo;

  /// No description provided for @profileFullName.
  ///
  /// In uz, this message translates to:
  /// **'F.I.SH'**
  String get profileFullName;

  /// No description provided for @profileAge.
  ///
  /// In uz, this message translates to:
  /// **'Yoshi'**
  String get profileAge;

  /// No description provided for @profileAgeValue.
  ///
  /// In uz, this message translates to:
  /// **'{age} yosh'**
  String profileAgeValue(String age);

  /// No description provided for @profilePhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get profilePhone;

  /// No description provided for @profileInfoHint.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni o\'zgartirish uchun administratorga murojaat qiling.'**
  String get profileInfoHint;

  /// No description provided for @profileCarYear.
  ///
  /// In uz, this message translates to:
  /// **'{year}-yil'**
  String profileCarYear(String year);

  /// No description provided for @profileDocuments.
  ///
  /// In uz, this message translates to:
  /// **'Hujjatlar'**
  String get profileDocuments;

  /// No description provided for @profileLicense.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchilik guvohnomasi'**
  String get profileLicense;

  /// No description provided for @profileTodayEarning.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi daromad'**
  String get profileTodayEarning;

  /// No description provided for @profileTotalEarning.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy daromad'**
  String get profileTotalEarning;

  /// No description provided for @profileByRoutes.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'nalishlar bo\'yicha'**
  String get profileByRoutes;

  /// No description provided for @profilePaymentNote.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov turi: naqd. Komissiya tarifi administrator tomonidan belgilanadi.'**
  String get profilePaymentNote;

  /// No description provided for @profileNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get profileNotifications;

  /// No description provided for @profileOrderSound.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma signali ovozi'**
  String get profileOrderSound;

  /// No description provided for @profileOrderSoundSub.
  ///
  /// In uz, this message translates to:
  /// **'Yangi buyurtma kelganda ovoz chiqadi'**
  String get profileOrderSoundSub;

  /// No description provided for @profileLanguageSection.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get profileLanguageSection;

  /// No description provided for @profileAppLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Ilova tili'**
  String get profileAppLanguage;

  /// No description provided for @guideStep1Body.
  ///
  /// In uz, this message translates to:
  /// **'Pastdagi tugmani o\'ngga suring — avtomobil belgisi tillo rangga o\'tadi va buyurtmalar kela boshlaydi.'**
  String get guideStep1Body;

  /// No description provided for @guideStep2Body.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma kelganda ovoz va tebranish bo\'ladi; 20 soniya ichida qabul qiling yoki o\'tkazib yuboring.'**
  String get guideStep2Body;

  /// No description provided for @guideStep3Body.
  ///
  /// In uz, this message translates to:
  /// **'Hech kim olmagan buyurtmalar ro\'yxatda turadi — xaritaning o\'ng yuqorisidagi tugma orqali oching.'**
  String get guideStep3Body;

  /// No description provided for @guideStep4Body.
  ///
  /// In uz, this message translates to:
  /// **'Tugmani chapga suring (faol buyurtma bo\'lmaganda) — liniyadan chiqasiz.'**
  String get guideStep4Body;

  /// No description provided for @guideStep5Body.
  ///
  /// In uz, this message translates to:
  /// **'Faqat oflayn va faol buyurtmasiz holatda mumkin — daromadingiz hisobda saqlanadi.'**
  String get guideStep5Body;

  /// No description provided for @statsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bugun · Statistika'**
  String get statsTitle;

  /// No description provided for @statsCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan'**
  String get statsCompleted;

  /// No description provided for @statsChartTitle.
  ///
  /// In uz, this message translates to:
  /// **'Daromad grafigi'**
  String get statsChartTitle;

  /// No description provided for @statsCompletedOrders.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan buyurtmalar ({count})'**
  String statsCompletedOrders(int count);

  /// No description provided for @statsNoOrders.
  ///
  /// In uz, this message translates to:
  /// **'Bu davrda buyurtma yo\'q'**
  String get statsNoOrders;

  /// No description provided for @statsNoData.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot yo\'q'**
  String get statsNoData;

  /// No description provided for @onlineServiceChannelName.
  ///
  /// In uz, this message translates to:
  /// **'Liniyada'**
  String get onlineServiceChannelName;

  /// No description provided for @onlineServiceChannelDesc.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchi liniyada — buyurtma kutilmoqda'**
  String get onlineServiceChannelDesc;

  /// No description provided for @onlineServiceNotifTitle.
  ///
  /// In uz, this message translates to:
  /// **'Liniyadasiz'**
  String get onlineServiceNotifTitle;

  /// No description provided for @onlineServiceNotifText.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma kutilmoqda'**
  String get onlineServiceNotifText;
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
