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
