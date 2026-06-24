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

  /// No description provided for @telegramFreeHint.
  ///
  /// In uz, this message translates to:
  /// **'Kodni bepul Telegram orqali oling'**
  String get telegramFreeHint;

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

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsTitle;

  /// No description provided for @accountTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisob'**
  String get accountTitle;

  /// No description provided for @guestUser.
  ///
  /// In uz, this message translates to:
  /// **'Mehmon'**
  String get guestUser;

  /// No description provided for @logoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingizdan chiqmoqchimisiz?'**
  String get logoutConfirm;

  /// No description provided for @personalInfo.
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlar'**
  String get personalInfo;

  /// No description provided for @profilePhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get profilePhone;

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

  /// No description provided for @restaurantsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonalar'**
  String get restaurantsTitle;

  /// No description provided for @open.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq'**
  String get closed;

  /// No description provided for @unavailable.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha yo\'q'**
  String get unavailable;

  /// No description provided for @priceSom.
  ///
  /// In uz, this message translates to:
  /// **'{amount} so\'m'**
  String priceSom(String amount);

  /// No description provided for @emptyRestaurants.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha oshxona yo\'q'**
  String get emptyRestaurants;

  /// No description provided for @emptyMenu.
  ///
  /// In uz, this message translates to:
  /// **'Menyu hozircha bo\'sh'**
  String get emptyMenu;

  /// No description provided for @foodSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona qidirish…'**
  String get foodSearchHint;

  /// No description provided for @foodFilterAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get foodFilterAll;

  /// No description provided for @foodFilterOpen.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get foodFilterOpen;

  /// No description provided for @foodFilterTop.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori reyting'**
  String get foodFilterTop;

  /// No description provided for @foodPromoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bepul yetkazib berish'**
  String get foodPromoTitle;

  /// No description provided for @foodPromoSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan oshxonalardan birinchi buyurtmaga'**
  String get foodPromoSubtitle;

  /// No description provided for @foodSectionRestaurants.
  ///
  /// In uz, this message translates to:
  /// **'Oshxonalar'**
  String get foodSectionRestaurants;

  /// No description provided for @foodNothingFound.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get foodNothingFound;

  /// No description provided for @greetingHi.
  ///
  /// In uz, this message translates to:
  /// **'Salom'**
  String get greetingHi;

  /// No description provided for @homeLocation.
  ///
  /// In uz, this message translates to:
  /// **'Beshariq tumani'**
  String get homeLocation;

  /// No description provided for @homePopular.
  ///
  /// In uz, this message translates to:
  /// **'Mashhur oshxonalar'**
  String get homePopular;

  /// No description provided for @homeAllRestaurants.
  ///
  /// In uz, this message translates to:
  /// **'Barcha oshxonalar'**
  String get homeAllRestaurants;

  /// No description provided for @homeSeeAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get homeSeeAll;

  /// No description provided for @homeBanner2Title.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi buyurtmaga -20%'**
  String get homeBanner2Title;

  /// No description provided for @homeBanner2Sub.
  ///
  /// In uz, this message translates to:
  /// **'Yangi mijozlar uchun chegirma'**
  String get homeBanner2Sub;

  /// No description provided for @homeBanner3Title.
  ///
  /// In uz, this message translates to:
  /// **'Tez va issiq'**
  String get homeBanner3Title;

  /// No description provided for @homeBanner3Sub.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha 30 daqiqada yetkazamiz'**
  String get homeBanner3Sub;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @cart.
  ///
  /// In uz, this message translates to:
  /// **'Savat'**
  String get cart;

  /// No description provided for @cartEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Savat bo\'sh'**
  String get cartEmpty;

  /// No description provided for @subtotalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Taomlar'**
  String get subtotalLabel;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish'**
  String get deliveryFeeLabel;

  /// No description provided for @totalLabel.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get totalLabel;

  /// No description provided for @checkoutButton.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma berish'**
  String get checkoutButton;

  /// No description provided for @checkoutTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rasmiylashtirish'**
  String get checkoutTitle;

  /// No description provided for @addressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish manzili'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'cha, uy, mo\'ljal'**
  String get addressHint;

  /// No description provided for @paymentMethod.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usuli'**
  String get paymentMethod;

  /// No description provided for @paymentCash.
  ///
  /// In uz, this message translates to:
  /// **'Naqd pul'**
  String get paymentCash;

  /// No description provided for @deliveryNote.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish narxi buyurtmaga qo\'shiladi'**
  String get deliveryNote;

  /// No description provided for @placeOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani tasdiqlash'**
  String get placeOrder;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma qabul qilindi'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedDesc.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmangiz oshxonaga yuborildi.'**
  String get orderPlacedDesc;

  /// No description provided for @myOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarim'**
  String get myOrders;

  /// No description provided for @noOrders.
  ///
  /// In uz, this message translates to:
  /// **'Hali buyurtma yo\'q'**
  String get noOrders;

  /// No description provided for @orderNo.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma #{no}'**
  String orderNo(String no);

  /// No description provided for @cancelOrder.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancelOrder;

  /// No description provided for @backToHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifaga'**
  String get backToHome;

  /// No description provided for @cartUpdatedNewRestaurant.
  ///
  /// In uz, this message translates to:
  /// **'Savat yangi oshxona uchun yangilandi'**
  String get cartUpdatedNewRestaurant;

  /// No description provided for @statusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilindi'**
  String get statusAccepted;

  /// No description provided for @statusOnTheWay.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lda'**
  String get statusOnTheWay;

  /// No description provided for @statusDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazildi'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilindi'**
  String get statusCancelled;

  /// No description provided for @statusFailed.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilmadi'**
  String get statusFailed;

  /// No description provided for @promoLabel.
  ///
  /// In uz, this message translates to:
  /// **'Promokod'**
  String get promoLabel;

  /// No description provided for @promoHint.
  ///
  /// In uz, this message translates to:
  /// **'Bor bo\'lsa kiriting'**
  String get promoHint;

  /// No description provided for @discountLabel.
  ///
  /// In uz, this message translates to:
  /// **'Chegirma'**
  String get discountLabel;

  /// No description provided for @promoInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Promokod yaroqsiz'**
  String get promoInvalid;

  /// No description provided for @partnerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hamkorlik'**
  String get partnerTitle;

  /// No description provided for @partnerBanner.
  ///
  /// In uz, this message translates to:
  /// **'Bizga hamkor bo\'ling'**
  String get partnerBanner;

  /// No description provided for @partnerBannerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona yoki haydovchi sifatida ariza qoldiring'**
  String get partnerBannerSubtitle;

  /// No description provided for @partnerFormTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hamkorlik arizasi'**
  String get partnerFormTitle;

  /// No description provided for @partnerFullName.
  ///
  /// In uz, this message translates to:
  /// **'F.I.Sh.'**
  String get partnerFullName;

  /// No description provided for @partnerFullNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ism familiyangiz'**
  String get partnerFullNameHint;

  /// No description provided for @partnerType.
  ///
  /// In uz, this message translates to:
  /// **'Hamkorlik turi'**
  String get partnerType;

  /// No description provided for @partnerTypeRestaurant.
  ///
  /// In uz, this message translates to:
  /// **'Oshxona'**
  String get partnerTypeRestaurant;

  /// No description provided for @partnerTypeDriver.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchi'**
  String get partnerTypeDriver;

  /// No description provided for @partnerNote.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (ixtiyoriy)'**
  String get partnerNote;

  /// No description provided for @partnerNoteHint.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shimcha ma\'lumot'**
  String get partnerNoteHint;

  /// No description provided for @partnerSubmit.
  ///
  /// In uz, this message translates to:
  /// **'Ariza yuborish'**
  String get partnerSubmit;

  /// No description provided for @partnerSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Arizangiz qabul qilindi'**
  String get partnerSubmitted;

  /// No description provided for @partnerMyApplications.
  ///
  /// In uz, this message translates to:
  /// **'Mening arizalarim'**
  String get partnerMyApplications;

  /// No description provided for @partnerNoApplications.
  ///
  /// In uz, this message translates to:
  /// **'Hali ariza yo\'q'**
  String get partnerNoApplications;

  /// No description provided for @partnerNameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ism kiritilishi shart'**
  String get partnerNameRequired;

  /// No description provided for @partnerStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rib chiqilmoqda'**
  String get partnerStatusPending;

  /// No description provided for @partnerStatusApproved.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlandi'**
  String get partnerStatusApproved;

  /// No description provided for @partnerStatusRejected.
  ///
  /// In uz, this message translates to:
  /// **'Rad etildi'**
  String get partnerStatusRejected;

  /// No description provided for @profileTitle.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In uz, this message translates to:
  /// **'Ism familiya'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get profileNameHint;

  /// No description provided for @profileSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In uz, this message translates to:
  /// **'Saqlandi'**
  String get profileSaved;

  /// No description provided for @addressesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Manzillarim'**
  String get addressesTitle;

  /// No description provided for @addressAdd.
  ///
  /// In uz, this message translates to:
  /// **'Manzil qo\'shish'**
  String get addressAdd;

  /// No description provided for @addressLabelField.
  ///
  /// In uz, this message translates to:
  /// **'Nomi (Uy, Ish...)'**
  String get addressLabelField;

  /// No description provided for @addressTextField.
  ///
  /// In uz, this message translates to:
  /// **'To\'liq manzil'**
  String get addressTextField;

  /// No description provided for @addressDefault.
  ///
  /// In uz, this message translates to:
  /// **'Standart'**
  String get addressDefault;

  /// No description provided for @addressSetDefault.
  ///
  /// In uz, this message translates to:
  /// **'Standart qilish'**
  String get addressSetDefault;

  /// No description provided for @addressDelete.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get addressDelete;

  /// No description provided for @addressNone.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan manzil yo\'q'**
  String get addressNone;

  /// No description provided for @addressDefaultBadge.
  ///
  /// In uz, this message translates to:
  /// **'Standart'**
  String get addressDefaultBadge;

  /// No description provided for @addressNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi manzil'**
  String get addressNew;

  /// No description provided for @addressChoose.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni tanlang'**
  String get addressChoose;

  /// No description provided for @taxiTitle.
  ///
  /// In uz, this message translates to:
  /// **'Taksi'**
  String get taxiTitle;

  /// No description provided for @taxiFrom.
  ///
  /// In uz, this message translates to:
  /// **'Qayerdan'**
  String get taxiFrom;

  /// No description provided for @taxiTo.
  ///
  /// In uz, this message translates to:
  /// **'Qayerga'**
  String get taxiTo;

  /// No description provided for @taxiEstimate.
  ///
  /// In uz, this message translates to:
  /// **'Narxni hisoblash'**
  String get taxiEstimate;

  /// No description provided for @taxiRequest.
  ///
  /// In uz, this message translates to:
  /// **'Taksi chaqirish'**
  String get taxiRequest;

  /// No description provided for @taxiDistance.
  ///
  /// In uz, this message translates to:
  /// **'Masofa'**
  String get taxiDistance;

  /// No description provided for @taxiFare.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get taxiFare;

  /// No description provided for @taxiKm.
  ///
  /// In uz, this message translates to:
  /// **'{km} km'**
  String taxiKm(String km);

  /// No description provided for @taxiSamePoint.
  ///
  /// In uz, this message translates to:
  /// **'Boshlanish va manzil bir xil bo\'lmasin'**
  String get taxiSamePoint;

  /// No description provided for @taxiActiveTrip.
  ///
  /// In uz, this message translates to:
  /// **'Joriy safar'**
  String get taxiActiveTrip;

  /// No description provided for @taxiMyTrips.
  ///
  /// In uz, this message translates to:
  /// **'Safarlarim'**
  String get taxiMyTrips;

  /// No description provided for @taxiNoTrips.
  ///
  /// In uz, this message translates to:
  /// **'Hali safar yo\'q'**
  String get taxiNoTrips;

  /// No description provided for @taxiRequested.
  ///
  /// In uz, this message translates to:
  /// **'Taksi chaqirildi'**
  String get taxiRequested;

  /// No description provided for @taxiCancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get taxiCancel;

  /// No description provided for @taxiTripNo.
  ///
  /// In uz, this message translates to:
  /// **'Safar #{no}'**
  String taxiTripNo(String no);

  /// No description provided for @taxiStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchi kutilmoqda'**
  String get taxiStatusPending;

  /// No description provided for @taxiStatusAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Haydovchi yo\'lda'**
  String get taxiStatusAccepted;

  /// No description provided for @taxiStatusInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'ldasiz'**
  String get taxiStatusInProgress;

  /// No description provided for @taxiStatusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlandi'**
  String get taxiStatusCompleted;

  /// No description provided for @taxiStatusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilindi'**
  String get taxiStatusCancelled;

  /// No description provided for @taxiNoDestination.
  ///
  /// In uz, this message translates to:
  /// **'Manzilni belgilamasdan chaqirish'**
  String get taxiNoDestination;

  /// No description provided for @taxiMeteredHint.
  ///
  /// In uz, this message translates to:
  /// **'Narx safar oxirida masofa bo\'yicha hisoblanadi'**
  String get taxiMeteredHint;

  /// No description provided for @taxiMeteredBadge.
  ///
  /// In uz, this message translates to:
  /// **'Manzilsiz'**
  String get taxiMeteredBadge;

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
  /// **'Haydovchi'**
  String get chatParty;

  /// No description provided for @parcelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka'**
  String get parcelTitle;

  /// No description provided for @parcelSize.
  ///
  /// In uz, this message translates to:
  /// **'O\'lcham'**
  String get parcelSize;

  /// No description provided for @parcelSizeSmall.
  ///
  /// In uz, this message translates to:
  /// **'Kichik'**
  String get parcelSizeSmall;

  /// No description provided for @parcelSizeMedium.
  ///
  /// In uz, this message translates to:
  /// **'O\'rta'**
  String get parcelSizeMedium;

  /// No description provided for @parcelSizeLarge.
  ///
  /// In uz, this message translates to:
  /// **'Katta'**
  String get parcelSizeLarge;

  /// No description provided for @parcelRecipientName.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi ismi'**
  String get parcelRecipientName;

  /// No description provided for @parcelRecipientPhone.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi telefoni'**
  String get parcelRecipientPhone;

  /// No description provided for @parcelNote.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (ixtiyoriy)'**
  String get parcelNote;

  /// No description provided for @parcelSend.
  ///
  /// In uz, this message translates to:
  /// **'Jo\'natish'**
  String get parcelSend;

  /// No description provided for @parcelSent.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka jo\'natildi'**
  String get parcelSent;

  /// No description provided for @parcelMyParcels.
  ///
  /// In uz, this message translates to:
  /// **'Dostavkalarim'**
  String get parcelMyParcels;

  /// No description provided for @parcelNoParcels.
  ///
  /// In uz, this message translates to:
  /// **'Hali dostavka yo\'q'**
  String get parcelNoParcels;

  /// No description provided for @parcelRecipientRequired.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi ism va telefoni kerak'**
  String get parcelRecipientRequired;

  /// No description provided for @parcelNo.
  ///
  /// In uz, this message translates to:
  /// **'Dostavka #{no}'**
  String parcelNo(String no);

  /// No description provided for @parcelStatusPending.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer kutilmoqda'**
  String get parcelStatusPending;

  /// No description provided for @parcelStatusAccepted.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer qabul qildi'**
  String get parcelStatusAccepted;

  /// No description provided for @parcelStatusPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'lda'**
  String get parcelStatusPickedUp;

  /// No description provided for @parcelStatusDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazildi'**
  String get parcelStatusDelivered;

  /// No description provided for @parcelStatusCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilindi'**
  String get parcelStatusCancelled;
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
