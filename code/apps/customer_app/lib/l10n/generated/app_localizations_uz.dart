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

  @override
  String get cart => 'Savat';

  @override
  String get cartEmpty => 'Savat bo\'sh';

  @override
  String get subtotalLabel => 'Taomlar';

  @override
  String get deliveryFeeLabel => 'Yetkazib berish';

  @override
  String get totalLabel => 'Jami';

  @override
  String get checkoutButton => 'Buyurtma berish';

  @override
  String get checkoutTitle => 'Rasmiylashtirish';

  @override
  String get addressLabel => 'Yetkazib berish manzili';

  @override
  String get addressHint => 'Ko\'cha, uy, mo\'ljal';

  @override
  String get paymentMethod => 'To\'lov usuli';

  @override
  String get paymentCash => 'Naqd pul';

  @override
  String get deliveryNote => 'Yetkazib berish narxi buyurtmaga qo\'shiladi';

  @override
  String get placeOrder => 'Buyurtmani tasdiqlash';

  @override
  String get orderPlacedTitle => 'Buyurtma qabul qilindi';

  @override
  String get orderPlacedDesc => 'Buyurtmangiz oshxonaga yuborildi.';

  @override
  String get myOrders => 'Buyurtmalarim';

  @override
  String get noOrders => 'Hali buyurtma yo\'q';

  @override
  String orderNo(String no) {
    return 'Buyurtma #$no';
  }

  @override
  String get cancelOrder => 'Bekor qilish';

  @override
  String get backToHome => 'Bosh sahifaga';

  @override
  String get cartUpdatedNewRestaurant => 'Savat yangi oshxona uchun yangilandi';

  @override
  String get statusPending => 'Kutilmoqda';

  @override
  String get statusAccepted => 'Qabul qilindi';

  @override
  String get statusOnTheWay => 'Yo\'lda';

  @override
  String get statusDelivered => 'Yetkazildi';

  @override
  String get statusCancelled => 'Bekor qilindi';

  @override
  String get statusFailed => 'Bajarilmadi';
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

  @override
  String get cart => 'Сават';

  @override
  String get cartEmpty => 'Сават бўш';

  @override
  String get subtotalLabel => 'Таомлар';

  @override
  String get deliveryFeeLabel => 'Етказиб бериш';

  @override
  String get totalLabel => 'Жами';

  @override
  String get checkoutButton => 'Буюртма бериш';

  @override
  String get checkoutTitle => 'Расмийлаштириш';

  @override
  String get addressLabel => 'Етказиб бериш манзили';

  @override
  String get addressHint => 'Кўча, уй, мўлжал';

  @override
  String get paymentMethod => 'Тўлов усули';

  @override
  String get paymentCash => 'Нақд пул';

  @override
  String get deliveryNote => 'Етказиб бериш нархи буюртмага қўшилади';

  @override
  String get placeOrder => 'Буюртмани тасдиқлаш';

  @override
  String get orderPlacedTitle => 'Буюртма қабул қилинди';

  @override
  String get orderPlacedDesc => 'Буюртмангиз ошхонага юборилди.';

  @override
  String get myOrders => 'Буюртмаларим';

  @override
  String get noOrders => 'Ҳали буюртма йўқ';

  @override
  String orderNo(String no) {
    return 'Буюртма #$no';
  }

  @override
  String get cancelOrder => 'Бекор қилиш';

  @override
  String get backToHome => 'Бош саҳифага';

  @override
  String get cartUpdatedNewRestaurant => 'Сават янги ошхона учун янгиланди';

  @override
  String get statusPending => 'Кутилмоқда';

  @override
  String get statusAccepted => 'Қабул қилинди';

  @override
  String get statusOnTheWay => 'Йўлда';

  @override
  String get statusDelivered => 'Етказилди';

  @override
  String get statusCancelled => 'Бекор қилинди';

  @override
  String get statusFailed => 'Бажарилмади';
}
