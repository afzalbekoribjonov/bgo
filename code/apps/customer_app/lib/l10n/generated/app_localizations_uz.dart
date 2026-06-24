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
  String get telegramFreeHint => 'Kodni bepul Telegram orqali oling';

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
  String get cancel => 'Bekor qilish';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get accountTitle => 'Hisob';

  @override
  String get guestUser => 'Mehmon';

  @override
  String get logoutConfirm => 'Hisobingizdan chiqmoqchimisiz?';

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
  String get foodSearchHint => 'Oshxona qidirish…';

  @override
  String get foodFilterAll => 'Hammasi';

  @override
  String get foodFilterOpen => 'Ochiq';

  @override
  String get foodFilterTop => 'Yuqori reyting';

  @override
  String get foodPromoTitle => 'Bepul yetkazib berish';

  @override
  String get foodPromoSubtitle => 'Tanlangan oshxonalardan birinchi buyurtmaga';

  @override
  String get foodSectionRestaurants => 'Oshxonalar';

  @override
  String get foodNothingFound => 'Hech narsa topilmadi';

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

  @override
  String get promoLabel => 'Promokod';

  @override
  String get promoHint => 'Bor bo\'lsa kiriting';

  @override
  String get discountLabel => 'Chegirma';

  @override
  String get promoInvalid => 'Promokod yaroqsiz';

  @override
  String get partnerTitle => 'Hamkorlik';

  @override
  String get partnerBanner => 'Bizga hamkor bo\'ling';

  @override
  String get partnerBannerSubtitle => 'Oshxona yoki haydovchi sifatida ariza qoldiring';

  @override
  String get partnerFormTitle => 'Hamkorlik arizasi';

  @override
  String get partnerFullName => 'F.I.Sh.';

  @override
  String get partnerFullNameHint => 'Ism familiyangiz';

  @override
  String get partnerType => 'Hamkorlik turi';

  @override
  String get partnerTypeRestaurant => 'Oshxona';

  @override
  String get partnerTypeDriver => 'Haydovchi';

  @override
  String get partnerNote => 'Izoh (ixtiyoriy)';

  @override
  String get partnerNoteHint => 'Qo\'shimcha ma\'lumot';

  @override
  String get partnerSubmit => 'Ariza yuborish';

  @override
  String get partnerSubmitted => 'Arizangiz qabul qilindi';

  @override
  String get partnerMyApplications => 'Mening arizalarim';

  @override
  String get partnerNoApplications => 'Hali ariza yo\'q';

  @override
  String get partnerNameRequired => 'Ism kiritilishi shart';

  @override
  String get partnerStatusPending => 'Ko\'rib chiqilmoqda';

  @override
  String get partnerStatusApproved => 'Tasdiqlandi';

  @override
  String get partnerStatusRejected => 'Rad etildi';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileName => 'Ism familiya';

  @override
  String get profileNameHint => 'Ismingizni kiriting';

  @override
  String get profileSave => 'Saqlash';

  @override
  String get profileSaved => 'Saqlandi';

  @override
  String get addressesTitle => 'Manzillarim';

  @override
  String get addressAdd => 'Manzil qo\'shish';

  @override
  String get addressLabelField => 'Nomi (Uy, Ish...)';

  @override
  String get addressTextField => 'To\'liq manzil';

  @override
  String get addressDefault => 'Standart';

  @override
  String get addressSetDefault => 'Standart qilish';

  @override
  String get addressDelete => 'O\'chirish';

  @override
  String get addressNone => 'Saqlangan manzil yo\'q';

  @override
  String get addressNew => 'Yangi manzil';

  @override
  String get addressChoose => 'Manzilni tanlang';

  @override
  String get taxiTitle => 'Taksi';

  @override
  String get taxiFrom => 'Qayerdan';

  @override
  String get taxiTo => 'Qayerga';

  @override
  String get taxiEstimate => 'Narxni hisoblash';

  @override
  String get taxiRequest => 'Taksi chaqirish';

  @override
  String get taxiDistance => 'Masofa';

  @override
  String get taxiFare => 'Narx';

  @override
  String taxiKm(String km) {
    return '$km km';
  }

  @override
  String get taxiSamePoint => 'Boshlanish va manzil bir xil bo\'lmasin';

  @override
  String get taxiActiveTrip => 'Joriy safar';

  @override
  String get taxiMyTrips => 'Safarlarim';

  @override
  String get taxiNoTrips => 'Hali safar yo\'q';

  @override
  String get taxiRequested => 'Taksi chaqirildi';

  @override
  String get taxiCancel => 'Bekor qilish';

  @override
  String taxiTripNo(String no) {
    return 'Safar #$no';
  }

  @override
  String get taxiStatusPending => 'Haydovchi kutilmoqda';

  @override
  String get taxiStatusAccepted => 'Haydovchi yo\'lda';

  @override
  String get taxiStatusInProgress => 'Yo\'ldasiz';

  @override
  String get taxiStatusCompleted => 'Yakunlandi';

  @override
  String get taxiStatusCancelled => 'Bekor qilindi';

  @override
  String get taxiNoDestination => 'Manzilni belgilamasdan chaqirish';

  @override
  String get taxiMeteredHint => 'Narx safar oxirida masofa bo\'yicha hisoblanadi';

  @override
  String get taxiMeteredBadge => 'Manzilsiz';

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
  String get chatParty => 'Haydovchi';

  @override
  String get parcelTitle => 'Dostavka';

  @override
  String get parcelSize => 'O\'lcham';

  @override
  String get parcelSizeSmall => 'Kichik';

  @override
  String get parcelSizeMedium => 'O\'rta';

  @override
  String get parcelSizeLarge => 'Katta';

  @override
  String get parcelRecipientName => 'Qabul qiluvchi ismi';

  @override
  String get parcelRecipientPhone => 'Qabul qiluvchi telefoni';

  @override
  String get parcelNote => 'Izoh (ixtiyoriy)';

  @override
  String get parcelSend => 'Jo\'natish';

  @override
  String get parcelSent => 'Dostavka jo\'natildi';

  @override
  String get parcelMyParcels => 'Dostavkalarim';

  @override
  String get parcelNoParcels => 'Hali dostavka yo\'q';

  @override
  String get parcelRecipientRequired => 'Qabul qiluvchi ism va telefoni kerak';

  @override
  String parcelNo(String no) {
    return 'Dostavka #$no';
  }

  @override
  String get parcelStatusPending => 'Kuryer kutilmoqda';

  @override
  String get parcelStatusAccepted => 'Kuryer qabul qildi';

  @override
  String get parcelStatusPickedUp => 'Yo\'lda';

  @override
  String get parcelStatusDelivered => 'Yetkazildi';

  @override
  String get parcelStatusCancelled => 'Bekor qilindi';
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
  String get telegramFreeHint => 'Кодни бепул Телеграм орқали олинг';

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
  String get cancel => 'Бекор қилиш';

  @override
  String get settingsTitle => 'Созламалар';

  @override
  String get accountTitle => 'Ҳисоб';

  @override
  String get guestUser => 'Меҳмон';

  @override
  String get logoutConfirm => 'Ҳисобингиздан чиқмоқчимисиз?';

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
  String get foodSearchHint => 'Ошхона қидириш…';

  @override
  String get foodFilterAll => 'Ҳаммаси';

  @override
  String get foodFilterOpen => 'Очиқ';

  @override
  String get foodFilterTop => 'Юқори рейтинг';

  @override
  String get foodPromoTitle => 'Бепул етказиб бериш';

  @override
  String get foodPromoSubtitle => 'Танланган ошхоналардан биринчи буюртмага';

  @override
  String get foodSectionRestaurants => 'Ошхоналар';

  @override
  String get foodNothingFound => 'Ҳеч нарса топилмади';

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

  @override
  String get promoLabel => 'Промокод';

  @override
  String get promoHint => 'Бор бўлса киритинг';

  @override
  String get discountLabel => 'Чегирма';

  @override
  String get promoInvalid => 'Промокод яроқсиз';

  @override
  String get partnerTitle => 'Ҳамкорлик';

  @override
  String get partnerBanner => 'Бизга ҳамкор бўлинг';

  @override
  String get partnerBannerSubtitle => 'Ошхона ёки ҳайдовчи сифатида ариза қолдиринг';

  @override
  String get partnerFormTitle => 'Ҳамкорлик аризаси';

  @override
  String get partnerFullName => 'Ф.И.Ш.';

  @override
  String get partnerFullNameHint => 'Исм фамилиянгиз';

  @override
  String get partnerType => 'Ҳамкорлик тури';

  @override
  String get partnerTypeRestaurant => 'Ошхона';

  @override
  String get partnerTypeDriver => 'Ҳайдовчи';

  @override
  String get partnerNote => 'Изоҳ (ихтиёрий)';

  @override
  String get partnerNoteHint => 'Қўшимча маълумот';

  @override
  String get partnerSubmit => 'Ариза юбориш';

  @override
  String get partnerSubmitted => 'Аризангиз қабул қилинди';

  @override
  String get partnerMyApplications => 'Менинг аризаларим';

  @override
  String get partnerNoApplications => 'Ҳали ариза йўқ';

  @override
  String get partnerNameRequired => 'Исм киритилиши шарт';

  @override
  String get partnerStatusPending => 'Кўриб чиқилмоқда';

  @override
  String get partnerStatusApproved => 'Тасдиқланди';

  @override
  String get partnerStatusRejected => 'Рад этилди';

  @override
  String get profileTitle => 'Профил';

  @override
  String get profileName => 'Исм фамилия';

  @override
  String get profileNameHint => 'Исмингизни киритинг';

  @override
  String get profileSave => 'Сақлаш';

  @override
  String get profileSaved => 'Сақланди';

  @override
  String get addressesTitle => 'Манзилларим';

  @override
  String get addressAdd => 'Манзил қўшиш';

  @override
  String get addressLabelField => 'Номи (Уй, Иш...)';

  @override
  String get addressTextField => 'Тўлиқ манзил';

  @override
  String get addressDefault => 'Стандарт';

  @override
  String get addressSetDefault => 'Стандарт қилиш';

  @override
  String get addressDelete => 'Ўчириш';

  @override
  String get addressNone => 'Сақланган манзил йўқ';

  @override
  String get addressNew => 'Янги манзил';

  @override
  String get addressChoose => 'Манзилни танланг';

  @override
  String get taxiTitle => 'Такси';

  @override
  String get taxiFrom => 'Қаердан';

  @override
  String get taxiTo => 'Қаерга';

  @override
  String get taxiEstimate => 'Нархни ҳисоблаш';

  @override
  String get taxiRequest => 'Такси чақириш';

  @override
  String get taxiDistance => 'Масофа';

  @override
  String get taxiFare => 'Нарх';

  @override
  String taxiKm(String km) {
    return '$km км';
  }

  @override
  String get taxiSamePoint => 'Бошланиш ва манзил бир хил бўлмасин';

  @override
  String get taxiActiveTrip => 'Жорий сафар';

  @override
  String get taxiMyTrips => 'Сафарларим';

  @override
  String get taxiNoTrips => 'Ҳали сафар йўқ';

  @override
  String get taxiRequested => 'Такси чақирилди';

  @override
  String get taxiCancel => 'Бекор қилиш';

  @override
  String taxiTripNo(String no) {
    return 'Сафар #$no';
  }

  @override
  String get taxiStatusPending => 'Ҳайдовчи кутилмоқда';

  @override
  String get taxiStatusAccepted => 'Ҳайдовчи йўлда';

  @override
  String get taxiStatusInProgress => 'Йўлдасиз';

  @override
  String get taxiStatusCompleted => 'Якунланди';

  @override
  String get taxiStatusCancelled => 'Бекор қилинди';

  @override
  String get taxiNoDestination => 'Манзилни белгиламасдан чақириш';

  @override
  String get taxiMeteredHint => 'Нарх сафар охирида масофа бўйича ҳисобланади';

  @override
  String get taxiMeteredBadge => 'Манзилсиз';

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
  String get chatParty => 'Ҳайдовчи';

  @override
  String get parcelTitle => 'Достевка';

  @override
  String get parcelSize => 'Ўлчам';

  @override
  String get parcelSizeSmall => 'Кичик';

  @override
  String get parcelSizeMedium => 'Ўрта';

  @override
  String get parcelSizeLarge => 'Катта';

  @override
  String get parcelRecipientName => 'Қабул қилувчи исми';

  @override
  String get parcelRecipientPhone => 'Қабул қилувчи телефони';

  @override
  String get parcelNote => 'Изоҳ (ихтиёрий)';

  @override
  String get parcelSend => 'Жўнатиш';

  @override
  String get parcelSent => 'Достевка жўнатилди';

  @override
  String get parcelMyParcels => 'Достевкаларим';

  @override
  String get parcelNoParcels => 'Ҳали достевка йўқ';

  @override
  String get parcelRecipientRequired => 'Қабул қилувчи исм ва телефони керак';

  @override
  String parcelNo(String no) {
    return 'Достевка #$no';
  }

  @override
  String get parcelStatusPending => 'Курьер кутилмоқда';

  @override
  String get parcelStatusAccepted => 'Курьер қабул қилди';

  @override
  String get parcelStatusPickedUp => 'Йўлда';

  @override
  String get parcelStatusDelivered => 'Етказилди';

  @override
  String get parcelStatusCancelled => 'Бекор қилинди';
}
