import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Beshariq';

  @override
  String get welcome => 'Xush kelibsiz!';

  @override
  String get chooseService => 'Xizmatni tanlang';

  @override
  String get serviceFood => 'Ovqat';

  @override
  String get serviceTaxi => 'Taksi';

  @override
  String get serviceDelivery => 'Dostavka';

  @override
  String get language => 'Til';

  @override
  String get loginTitle => 'Kirish / Ro\'yxatdan o\'tish';

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
  String get consentTitle => 'Maxfiylik va shartlar';

  @override
  String get consentBody => 'Davom etish orqali siz Foydalanish shartlari va Maxfiylik siyosatiga rozilik bildirasiz. Joylashuv ma\'lumotlari xizmat ko\'rsatish uchun ishlatiladi.';

  @override
  String get consentCheckbox => 'Men shartlar va maxfiylik siyosatiga roziman';

  @override
  String get continueButton => 'Davom etish';

  @override
  String get logout => 'Chiqish';

  @override
  String get errorInvalidPhone => 'Telefon raqami noto\'g\'ri (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Kod noto\'g\'ri yoki muddati tugagan';

  @override
  String get errorGeneric => 'Xatolik yuz berdi. Qayta urinib ko\'ring.';

  @override
  String get errorNetwork => 'Internet aloqasi yo\'q';

  @override
  String get restaurantsTitle => 'Oshxonalar';

  @override
  String get open => 'Ochiq';

  @override
  String get closed => 'Yopiq';

  @override
  String get unavailable => 'Hozircha yo\'q';

  @override
  String priceSom(String amount) {
    return '$amount so\'m';
  }

  @override
  String get emptyRestaurants => 'Hozircha oshxona yo\'q';

  @override
  String get emptyMenu => 'Menyu hozircha bo\'sh';

  @override
  String get retry => 'Qayta urinish';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl(): super('uz_Cyrl');

  @override
  String get appName => 'Бешариқ';

  @override
  String get welcome => 'Хуш келибсиз!';

  @override
  String get chooseService => 'Хизматни танланг';

  @override
  String get serviceFood => 'Овқат';

  @override
  String get serviceTaxi => 'Такси';

  @override
  String get serviceDelivery => 'Доставка';

  @override
  String get language => 'Тил';

  @override
  String get loginTitle => 'Кириш / Рўйхатдан ўтиш';

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
  String get consentTitle => 'Махфийлик ва шартлар';

  @override
  String get consentBody => 'Давом этиш орқали сиз Фойдаланиш шартлари ва Махфийлик сиёсатига розилик билдирасиз. Жойлашув маълумотлари хизмат кўрсатиш учун ишлатилади.';

  @override
  String get consentCheckbox => 'Мен шартлар ва махфийлик сиёсатига розиман';

  @override
  String get continueButton => 'Давом этиш';

  @override
  String get logout => 'Чиқиш';

  @override
  String get errorInvalidPhone => 'Телефон рақами нотўғри (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Код нотўғри ёки муддати тугаган';

  @override
  String get errorGeneric => 'Хатолик юз берди. Қайта уриниб кўринг.';

  @override
  String get errorNetwork => 'Интернет алоқаси йўқ';

  @override
  String get restaurantsTitle => 'Ошхоналар';

  @override
  String get open => 'Очиқ';

  @override
  String get closed => 'Ёпиқ';

  @override
  String get unavailable => 'Ҳозирча йўқ';

  @override
  String priceSom(String amount) {
    return '$amount сўм';
  }

  @override
  String get emptyRestaurants => 'Ҳозирча ошхона йўқ';

  @override
  String get emptyMenu => 'Меню ҳозирча бўш';

  @override
  String get retry => 'Қайта уриниш';
}
