import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Beshariq Haydovchi';

  @override
  String get language => 'Til';

  @override
  String get logout => 'Chiqish';

  @override
  String get loginTitle => 'Haydovchi kirishi';

  @override
  String get loginSubtitle => 'Davom etish uchun telefon raqamingizni kiriting';

  @override
  String get phoneLabel => 'Telefon raqami';

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get otpTitle => 'Tasdiqlash kodi';

  @override
  String otpSubtitle(String phone) {
    return '$phone raqamiga yuborilgan kodni kiriting';
  }

  @override
  String get otpLabel => 'Kod';

  @override
  String get verify => 'Tasdiqlash';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String devCodeHint(String code) {
    return 'Sinov rejimi — kod: $code';
  }

  @override
  String get online => 'Onlayn';

  @override
  String get offline => 'Oflayn';

  @override
  String get offlineHint => 'Buyurtmalarni ko\'rish uchun onlayn bo\'ling';

  @override
  String get availableTitle => 'Mavjud buyurtmalar';

  @override
  String get myDeliveriesTitle => 'Mening yetkazishlarim';

  @override
  String get noAvailable => 'Hozircha buyurtma yo\'q';

  @override
  String get noDeliveries => 'Faol yetkazish yo\'q';

  @override
  String get accept => 'Qabul qilish';

  @override
  String get markPicked => 'Oldim';

  @override
  String get markDelivered => 'Yetkazdim';

  @override
  String get deliverTo => 'Manzil';

  @override
  String orderNo(String no) {
    return 'Buyurtma #$no';
  }

  @override
  String priceSom(String amount) {
    return '$amount so\'m';
  }

  @override
  String get statusAssigned => 'Sizga biriktirildi';

  @override
  String get statusPickedUp => 'Yo\'lda';

  @override
  String get earningsTitle => 'Daromadim';

  @override
  String get earningsToday => 'Bugun';

  @override
  String get earningsTotal => 'Jami';

  @override
  String deliveriesCount(int count) {
    return '$count ta yetkazish';
  }

  @override
  String get yourEarning => 'Daromad';

  @override
  String get deliveryTab => 'Yetkazish';

  @override
  String get taxiTab => 'Taksi';

  @override
  String get taxiAvailableTitle => 'Mavjud safarlar';

  @override
  String get taxiMyTripsTitle => 'Mening safarlarim';

  @override
  String get taxiNoAvailable => 'Hozircha safar yo\'q';

  @override
  String get taxiNoActive => 'Faol safar yo\'q';

  @override
  String get taxiStart => 'Yo\'lovchini oldim';

  @override
  String get taxiComplete => 'Yakunlash';

  @override
  String get taxiCompleteTitle => 'Safarni yakunlash';

  @override
  String get taxiDistanceKm => 'Masofa (km)';

  @override
  String get taxiWaitMinutes => 'Kutish (daqiqa)';

  @override
  String get taxiMeteredBadge => 'Manzilsiz';

  @override
  String get taxiMeteredFareHint => 'Narx yakunda hisoblanadi';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get chatTitle => 'Suhbat';

  @override
  String get chatInputHint => 'Xabar yozing…';

  @override
  String get chatEmpty => 'Hali xabar yo\'q. Suhbatni boshlang.';

  @override
  String get chatGreetingNote => 'Birinchi xabar «Assalomu alaykum,» bilan boshlanadi';

  @override
  String get chatYou => 'Siz';

  @override
  String get chatParty => 'Mijoz';

  @override
  String taxiTripNo(String no) {
    return 'Safar #$no';
  }

  @override
  String taxiKm(String km) {
    return '$km km';
  }

  @override
  String get taxiStatusAccepted => 'Qabul qilindi';

  @override
  String get taxiStatusInProgress => 'Yo\'lda';

  @override
  String get parcelTab => 'Dostavka';

  @override
  String get parcelAvailableTitle => 'Mavjud dostavkalar';

  @override
  String get parcelMyTitle => 'Mening dostavkalarim';

  @override
  String get parcelNoAvailable => 'Hozircha dostavka yo\'q';

  @override
  String get parcelNoActive => 'Faol dostavka yo\'q';

  @override
  String parcelNo(String no) {
    return 'Dostavka #$no';
  }

  @override
  String get parcelStatusPickedUp => 'Yo\'lda';

  @override
  String get errorInvalidPhone => 'Telefon raqami noto\'g\'ri (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Kod noto\'g\'ri yoki muddati tugagan';

  @override
  String get errorGeneric => 'Xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get errorNetwork => 'Internet aloqasi yo\'q';

  @override
  String get retry => 'Qayta urinish';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl(): super('uz_Cyrl');

  @override
  String get appName => 'Бешариқ Ҳайдовчи';

  @override
  String get language => 'Тил';

  @override
  String get logout => 'Чиқиш';

  @override
  String get loginTitle => 'Ҳайдовчи кириши';

  @override
  String get loginSubtitle => 'Давом этиш учун телефон рақамингизни киритинг';

  @override
  String get phoneLabel => 'Телефон рақами';

  @override
  String get sendCode => 'Код юбориш';

  @override
  String get otpTitle => 'Тасдиқлаш коди';

  @override
  String otpSubtitle(String phone) {
    return '$phone рақамига юборилган кодни киритинг';
  }

  @override
  String get otpLabel => 'Код';

  @override
  String get verify => 'Тасдиқлаш';

  @override
  String get resendCode => 'Кодни қайта юбориш';

  @override
  String devCodeHint(String code) {
    return 'Синов режими — код: $code';
  }

  @override
  String get online => 'Онлайн';

  @override
  String get offline => 'Офлайн';

  @override
  String get offlineHint => 'Буюртмаларни кўриш учун онлайн бўлинг';

  @override
  String get availableTitle => 'Мавжуд буюртмалар';

  @override
  String get myDeliveriesTitle => 'Менинг етказишларим';

  @override
  String get noAvailable => 'Ҳозирча буюртма йўқ';

  @override
  String get noDeliveries => 'Фаол етказиш йўқ';

  @override
  String get accept => 'Қабул қилиш';

  @override
  String get markPicked => 'Олдим';

  @override
  String get markDelivered => 'Етказдим';

  @override
  String get deliverTo => 'Манзил';

  @override
  String orderNo(String no) {
    return 'Буюртма #$no';
  }

  @override
  String priceSom(String amount) {
    return '$amount сўм';
  }

  @override
  String get statusAssigned => 'Сизга бириктирилди';

  @override
  String get statusPickedUp => 'Йўлда';

  @override
  String get earningsTitle => 'Даромадим';

  @override
  String get earningsToday => 'Бугун';

  @override
  String get earningsTotal => 'Жами';

  @override
  String deliveriesCount(int count) {
    return '$count та етказиш';
  }

  @override
  String get yourEarning => 'Даромад';

  @override
  String get deliveryTab => 'Етказиш';

  @override
  String get taxiTab => 'Такси';

  @override
  String get taxiAvailableTitle => 'Мавжуд сафарлар';

  @override
  String get taxiMyTripsTitle => 'Менинг сафарларим';

  @override
  String get taxiNoAvailable => 'Ҳозирча сафар йўқ';

  @override
  String get taxiNoActive => 'Фаол сафар йўқ';

  @override
  String get taxiStart => 'Йўловчини олдим';

  @override
  String get taxiComplete => 'Якунлаш';

  @override
  String get taxiCompleteTitle => 'Сафарни якунлаш';

  @override
  String get taxiDistanceKm => 'Масофа (км)';

  @override
  String get taxiWaitMinutes => 'Кутиш (дақиқа)';

  @override
  String get taxiMeteredBadge => 'Манзилсиз';

  @override
  String get taxiMeteredFareHint => 'Нарх якунда ҳисобланади';

  @override
  String get cancel => 'Бекор қилиш';

  @override
  String get chatTitle => 'Суҳбат';

  @override
  String get chatInputHint => 'Хабар ёзинг…';

  @override
  String get chatEmpty => 'Ҳали хабар йўқ. Суҳбатни бошланг.';

  @override
  String get chatGreetingNote => 'Биринчи хабар «Ассалому алайкум,» билан бошланади';

  @override
  String get chatYou => 'Сиз';

  @override
  String get chatParty => 'Мижоз';

  @override
  String taxiTripNo(String no) {
    return 'Сафар #$no';
  }

  @override
  String taxiKm(String km) {
    return '$km км';
  }

  @override
  String get taxiStatusAccepted => 'Қабул қилинди';

  @override
  String get taxiStatusInProgress => 'Йўлда';

  @override
  String get parcelTab => 'Достевка';

  @override
  String get parcelAvailableTitle => 'Мавжуд достевкалар';

  @override
  String get parcelMyTitle => 'Менинг достевкаларим';

  @override
  String get parcelNoAvailable => 'Ҳозирча достевка йўқ';

  @override
  String get parcelNoActive => 'Фаол достевка йўқ';

  @override
  String parcelNo(String no) {
    return 'Достевка #$no';
  }

  @override
  String get parcelStatusPickedUp => 'Йўлда';

  @override
  String get errorInvalidPhone => 'Телефон рақами нотўғри (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Код нотўғри ёки муддати тугаган';

  @override
  String get errorGeneric => 'Хатолик юз берди. Қайта уриниб кўринг.';

  @override
  String get errorNetwork => 'Интернет алоқаси йўқ';

  @override
  String get retry => 'Қайта уриниш';
}
