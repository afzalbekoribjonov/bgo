import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appName => 'Beshariq Haydovchi';

  @override
  String get noInternetConnection => 'Internet aloqasi yo\'q';

  @override
  String get homeGpsRequired => 'Liniyaga chiqish uchun GPS yoqilgan bo\'lishi kerak. Joylashuv ruxsatini tekshiring.';

  @override
  String get homeReconnecting => 'Qayta ulanmoqda...';

  @override
  String get homeAddressSearchHint => 'Manzil qidirish...';

  @override
  String get homeAddressPinHint => 'Xaritada uy manzilingizni belgilang';

  @override
  String get homeAddressConfirm => 'Manzilni tasdiqlash';

  @override
  String get homeAddressUnknownPoint => 'Belgilangan nuqta';

  @override
  String get navTurnLeft => 'Chapga';

  @override
  String get navTurnRight => 'O\'ngga';

  @override
  String get navTurnSharpLeft => 'Keskin chapga';

  @override
  String get navTurnSharpRight => 'Keskin o\'ngga';

  @override
  String get navTurnSlightLeft => 'Bir oz chapga';

  @override
  String get navTurnSlightRight => 'Bir oz o\'ngga';

  @override
  String get navTurnUturn => 'Orqaga qayting';

  @override
  String get navTurnRoundabout => 'Aylanma yo\'l';

  @override
  String navTurnBanner(int distance, String direction) {
    return '$distance m dan so\'ng $direction';
  }

  @override
  String navSpeakTurn(int distance, String direction) {
    return '$distance metrdan so\'ng $direction';
  }

  @override
  String navStraightBanner(int km) {
    return 'To\'g\'riga $km km';
  }

  @override
  String navSpeakStraight(int km) {
    return 'To\'g\'riga $km kilometr';
  }

  @override
  String get navTrafficLightBanner => 'Svetofor';

  @override
  String get navSpeakTrafficLight => 'Oldinda nazorat svetofori';

  @override
  String get homeModeTitle => 'Uyga rejimi';

  @override
  String get homeModeSetAddressFirst => 'Avval uy manzilini belgilang';

  @override
  String get homeModeLabel => 'Uyga';

  @override
  String get homeModeEditAddress => 'Manzilni o\'zgartirish';

  @override
  String get homeModePoolButton => 'Yo\'l-yo\'lakay buyurtma olish';

  @override
  String get homeModeToggleFailed => 'Rejimni o\'zgartirib bo\'lmadi';

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
  String get supportTitle => 'Yordam';

  @override
  String get supportProfileSub => 'Savollar va tez yordam';

  @override
  String get supportNewRequest => 'Yangi murojaat';

  @override
  String get supportHistoryEmpty => 'Hali murojaatlar yo\'q';

  @override
  String get supportHistoryEmptySub => 'Savolingiz bo\'lsa, pastdagi tugma orqali murojaat qiling';

  @override
  String get supportAiTopic => 'Erkin suhbat (AI)';

  @override
  String get supportMenuHeadline => 'Sizga qanday yordam bera olamiz?';

  @override
  String get supportMenuSub => 'Tayyor savollardan birini tanlang yoki AI yordamchiga murojaat qiling';

  @override
  String get supportAskQuestion => 'Savolim bor';

  @override
  String get supportInputHint => 'Savolingizni yozing…';

  @override
  String get supportEscalatedBanner => 'Bu suhbat administratorga yuborildi — tez orada siz bilan bog\'lanishadi.';

  @override
  String get supportStatusOpen => 'Ochiq';

  @override
  String get supportStatusEscalated => 'Adminga yuborilgan';

  @override
  String get supportStatusResolved => 'Yechilgan';

  @override
  String get supportSenderAdmin => 'Administrator';

  @override
  String get supportSenderAi => 'AI yordamchi';

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

  @override
  String get vertFood => 'Ovqat';

  @override
  String get labelKitchen => 'Oshxona';

  @override
  String get labelCustomer => 'Mijoz';

  @override
  String get labelPassenger => 'Yo\'lovchi';

  @override
  String minutesValue(int min) {
    return '$min daqiqa';
  }

  @override
  String get cancelReasonVehicle => 'Mashina bilan bog\'liq muammo';

  @override
  String get cancelReasonTooFar => 'Masofa juda uzoq';

  @override
  String get cancelReasonCannotReach => 'Mijoz bilan bog\'lana olmadim';

  @override
  String get cancelReasonNotAtAddress => 'Mijoz manzilda topilmadi';

  @override
  String get cancelReasonOther => 'Boshqa sabab';

  @override
  String get cancelReasonTitleCancel => 'Bekor qilish sababi';

  @override
  String get cancelReasonTitleDecline => 'Voz kechish sababi';

  @override
  String get cancelReasonHint => 'Sababni tanlang. Bekor qilish uchun balansingizdan jarima yechiladi.';

  @override
  String get cancelReasonNoteLabel => 'Sababni yozing';

  @override
  String get cancelReasonSubmitDecline => 'Voz kechish';

  @override
  String get homeOrderGone => 'Buyurtma endi mavjud emas';

  @override
  String get homeOrderCancelled => 'Buyurtma bekor qilindi';

  @override
  String get homeNoPhone => 'Raqam mavjud emas';

  @override
  String get homeDialerFailed => 'Telefon ilovasi ochilmadi';

  @override
  String get homeActionFailed => 'Amalni bajarib bo\'lmadi';

  @override
  String get homeCancelledOfferedToOther => 'Buyurtma boshqa kuryerga taklif qilinadi';

  @override
  String get homeZeroBalance => 'Balansingiz 0. Liniyaga chiqish uchun hisobni to\'ldiring.';

  @override
  String get homeGenericError => 'Xatolik';

  @override
  String get driverBlockedTitle => 'Vaqtinchalik bloklangansiz';

  @override
  String get driverBlockedNoReason => 'Administrator sababini ko\'rsatmagan.';

  @override
  String get driverBlockedUntilLabel => 'Qolgan vaqt';

  @override
  String driverBlockedDaysHours(int days, int hours) {
    return '$days kun $hours soat';
  }

  @override
  String driverBlockedHoursMinutes(int hours, int min) {
    return '$hours soat $min daqiqa';
  }

  @override
  String get driverBlockedOfficeNote => 'Darhol blokdan chiqish uchun ofisga kelib jarima to\'lang — administrator sizni darhol blokdan chiqaradi.';

  @override
  String get driverBlockedClose => 'Yopish';

  @override
  String get homeNewOrder => 'Yangi buyurtma';

  @override
  String get homeTapToDismiss => 'Bekor qilish uchun bosing';

  @override
  String get homeDistance => 'Masofa';

  @override
  String get homePrice => 'Narx';

  @override
  String homePickupEarningLine(String pickup, String amount) {
    return '$pickup · ulush +$amount so\'m';
  }

  @override
  String get homeTakeOrder => 'Buyurtmani olish';

  @override
  String get homeCashPayment => 'Naqd to\'lov';

  @override
  String get homeCollectFromCustomer => 'Mijozdan olasiz';

  @override
  String get homePayKitchen => 'Oshxonaga to\'laysiz';

  @override
  String get homeYourEarning => 'Daromadingiz';

  @override
  String get homeServiceFeeBalance => 'Xizmat haqi (balansdan)';

  @override
  String get homeOrderNotTaken => 'Buyurtma olinmadi';

  @override
  String get walletTitle => 'Hisobim';

  @override
  String get homeTodayCard => 'Bugun';

  @override
  String homeTodayCount(int count) {
    return '$count ta zakaz';
  }

  @override
  String get homeFinishWork => 'Ishni yakunlash';

  @override
  String get homeGoOnline => 'Liniyaga chiqish';

  @override
  String get homeKitchenPicked => 'OSHXONA · OLINDI';

  @override
  String get homeKitchenToPickup => 'OSHXONA · OLIB KETISH';

  @override
  String get homeCustomerAddress => 'MIJOZ MANZILI';

  @override
  String get homeCancelShort => 'Bekor';

  @override
  String get homePreparingBanner => 'Oshxonada tayyorlanmoqda — tayyor bo\'lganda oling';

  @override
  String get actionArrived => 'Yetib keldim';

  @override
  String get actionSetOff => 'Yo\'lga chiqish';

  @override
  String get actionFinishTrip => 'Safarni yakunlash';

  @override
  String get actionPickedOrder => 'Buyurtmani oldim';

  @override
  String get actionDelivered => 'Yetkazildi';

  @override
  String get actionPreparing => 'Tayyorlanmoqda…';

  @override
  String get actionPickedParcel => 'Dastavkani oldim';

  @override
  String get homeCashToKitchen => 'Oshxonaga naqd';

  @override
  String get homeToSender => 'Jo\'natuvchigacha';

  @override
  String get homeRecipientCall => 'Qabul qiluvchi · qo\'ng\'iroq';

  @override
  String get homeRecipient => 'Qabul qiluvchi';

  @override
  String get homeToCustomer => 'Mijozgacha';

  @override
  String get homeWaiting => 'Kutish';

  @override
  String get homeStart => 'Boshlash';

  @override
  String get homeWaitingStop => 'Kutyapti — to\'xtatish';

  @override
  String get homePaidWait => 'Pulli kutish';

  @override
  String get homeFreeWait => 'Bepul kutish';

  @override
  String get statusTaxiAccepted => 'Mijoz oldiga boring';

  @override
  String get statusTaxiArrived => 'Yo\'lovchini kuting';

  @override
  String get statusTaxiInProgress => 'Manzilga yo\'ldasiz';

  @override
  String get statusFoodPending => 'Oshxona tasdig\'i kutilmoqda';

  @override
  String get statusFoodAccepted => 'Oshxonaga boring · tayyorlanmoqda';

  @override
  String get statusFoodReady => 'Buyurtma tayyor · oling';

  @override
  String get statusFoodPicked => 'Mijozga yetkazing';

  @override
  String get statusParcelAccepted => 'Jo\'natuvchiga boring';

  @override
  String get statusParcelArrived => 'Posilkani oling';

  @override
  String get statusParcelPicked => 'Yo\'lga chiqing';

  @override
  String get statusParcelTransit => 'Qabul qiluvchiga yo\'ldasiz';

  @override
  String get summaryFoodTitle => 'Buyurtma yetkazildi';

  @override
  String get summaryTaxiTitle => 'Safar yakunlandi';

  @override
  String get summaryParcelTitle => 'Dostavka yakunlandi';

  @override
  String get sumKitchenCash => 'Oshxonaga to\'lang (naqd)';

  @override
  String get sumDeliveryEarning => 'Daromadingiz (yetkazish)';

  @override
  String get sumTaxiFare => 'Safar narxi';

  @override
  String get sumPickupSurcharge => 'Olib ketish ustamasi';

  @override
  String get sumDistance => 'Yurilgan masofa';

  @override
  String get sumTripTime => 'Safar vaqti';

  @override
  String get sumParcelFare => 'Dostavka narxi';

  @override
  String get sumSize => 'O\'lcham';

  @override
  String get sumTimeLabel => 'Vaqt';

  @override
  String get collectFromPassenger => 'Yo\'lovchidan oling';

  @override
  String get collectFromCustomer => 'Mijozdan oling';

  @override
  String get doneButton => 'Bajarildi';

  @override
  String get sizeSmall => 'Kichik';

  @override
  String get sizeLarge => 'Katta';

  @override
  String get sizeMedium => 'O\'rta';

  @override
  String get walletBalancePrefix => 'Joriy balans';

  @override
  String get periodDaily => 'Kunlik';

  @override
  String get periodWeekly => 'Haftalik';

  @override
  String get periodMonthly => 'Oylik';

  @override
  String get balanceTopupHistory => 'To\'ldirish tarixi';

  @override
  String get balanceNoTopups => 'Bu davrda to\'ldirish bo\'lmagan';

  @override
  String get balanceCurrent => 'Joriy balans';

  @override
  String get balanceLow => 'Kam';

  @override
  String get balanceCanAccept => 'Buyurtmalarni qabul qilishingiz mumkin';

  @override
  String get balanceMustTopup => 'Buyurtma olish uchun hisobni to\'ldiring';

  @override
  String get balanceSupportNote => 'Hisobni to\'ldirish uchun qo\'llab-quvvatlash xizmatiga murojaat qiling yoki ofisga tashrif buyuring.';

  @override
  String get msgTitle => 'Xabarlar';

  @override
  String get msgRefresh => 'Yangilash';

  @override
  String get msgEmptyTitle => 'Hozircha xabar yo\'q';

  @override
  String get msgEmptySubtitle => 'Admin xabarlari shu yerda ko\'rinadi';

  @override
  String get dayToday => 'Bugun';

  @override
  String get dayYesterday => 'Kecha';

  @override
  String get msgToYou => 'Sizga';

  @override
  String get msgAnnouncement => 'E\'lon';

  @override
  String get msgNewBadge => 'Yangi';

  @override
  String get navDeliverToAddress => 'Manzilga yetkazish';

  @override
  String get navGoPickupCustomer => 'Mijozni olib ketishga';

  @override
  String navEtaChip(String min, String km) {
    return '~$min daq · $km km';
  }

  @override
  String get poolTitle => 'Bo\'sh buyurtmalar';

  @override
  String get poolEmpty => 'Hozircha bo\'sh buyurtma yo\'q';

  @override
  String get poolLoading => 'Yuklanmoqda…';

  @override
  String get poolTake => 'Olish';

  @override
  String get tripChatNetworkError => 'Tarmoq xatosi — xabar yuborilmadi, qayta urining';

  @override
  String get tripChatEnded => 'Bu suhbatga hozir yozib bo\'lmaydi';

  @override
  String get tripChatSendFailed => 'Xabar yuborilmadi, qayta urining';

  @override
  String get tripChatCallTooltip => 'Qo\'ng\'iroq';

  @override
  String get tripChatConnecting => 'aloqa kutilmoqda…';

  @override
  String get tripChatLabel => 'suhbat';

  @override
  String get tripChatOffline => 'Internet aloqasi yo\'q — qayta ulanmoqda…';

  @override
  String get tripChatEmptyTitle => 'Hali xabar yo\'q';

  @override
  String get tripChatEmptySubtitle => 'Birinchi bo\'lib yozing 👋';

  @override
  String get profileTitle => 'Sozlamalar';

  @override
  String get profileAccountSection => 'Hisob';

  @override
  String get profileMyInfo => 'Ma\'lumotlarim';

  @override
  String get profileMyInfoSub => 'F.I.SH, yosh, telefon';

  @override
  String get profileMyCar => 'Mening mashinam';

  @override
  String get profileMyCarSub => 'Avtomobil va guvohnoma';

  @override
  String get profileTariffs => 'Tariflar va daromad';

  @override
  String get profileTariffsSub => 'Bugungi va umumiy daromad';

  @override
  String get profileSettingsSection => 'Sozlamalar';

  @override
  String get profileSoundLang => 'Ovoz va til';

  @override
  String get profileSoundLangSub => 'Signal ovozi, ilova tili';

  @override
  String get profileGuide => 'Yo\'riqnoma';

  @override
  String get profileGuideSub => 'Ilovadan qanday foydalanish';

  @override
  String get profileExitApp => 'Ilovadan chiqish';

  @override
  String get profileLogout => 'Hisobdan chiqish';

  @override
  String get profileExitHintOnline => 'Avval «Ishni yakunlash»ni bosing — liniyada turib ilovani yopib bo\'lmaydi.';

  @override
  String get profileExitHintActive => 'Faol buyurtmangiz bor — yakunlamaguncha ilova yopilmaydi.';

  @override
  String get profileCannotExitOnline => 'Liniyadasiz — avval ishni yakunlang.';

  @override
  String get profileCannotExitActive => 'Faol buyurtmangiz bor.';

  @override
  String get profileLogoutDialogContent => 'Hisobingizdan chiqmoqchimisiz? Qayta kirish uchun administrator bergan 8 xonali kod kerak bo\'ladi.';

  @override
  String get profileYesExit => 'Ha, chiqish';

  @override
  String get profileOnlineBadge => 'Liniyada';

  @override
  String get profileOfflineBadge => 'Oflayn';

  @override
  String get profilePersonalInfo => 'Shaxsiy ma\'lumotlar';

  @override
  String get profileFullName => 'F.I.SH';

  @override
  String get profileAge => 'Yoshi';

  @override
  String profileAgeValue(String age) {
    return '$age yosh';
  }

  @override
  String get profilePhone => 'Telefon';

  @override
  String get profileInfoHint => 'Ma\'lumotlarni o\'zgartirish uchun administratorga murojaat qiling.';

  @override
  String profileCarYear(String year) {
    return '$year-yil';
  }

  @override
  String get profileDocuments => 'Hujjatlar';

  @override
  String get profileLicense => 'Haydovchilik guvohnomasi';

  @override
  String get profileTodayEarning => 'Bugungi daromad';

  @override
  String get profileTotalEarning => 'Umumiy daromad';

  @override
  String get profileByRoutes => 'Yo\'nalishlar bo\'yicha';

  @override
  String get profilePaymentNote => 'To\'lov turi: naqd. Komissiya tarifi administrator tomonidan belgilanadi.';

  @override
  String get profileNotifications => 'Bildirishnomalar';

  @override
  String get profileOrderSound => 'Buyurtma signali ovozi';

  @override
  String get profileOrderSoundSub => 'Yangi buyurtma kelganda ovoz chiqadi';

  @override
  String get profileLanguageSection => 'Til';

  @override
  String get profileAppLanguage => 'Ilova tili';

  @override
  String get guideStep1Body => 'Pastdagi tugmani o\'ngga suring — avtomobil belgisi tillo rangga o\'tadi va buyurtmalar kela boshlaydi.';

  @override
  String get guideStep2Body => 'Buyurtma kelganda ovoz va tebranish bo\'ladi; 20 soniya ichida qabul qiling yoki o\'tkazib yuboring.';

  @override
  String get guideStep3Body => 'Hech kim olmagan buyurtmalar ro\'yxatda turadi — xaritaning o\'ng yuqorisidagi tugma orqali oching.';

  @override
  String get guideStep4Body => 'Tugmani chapga suring (faol buyurtma bo\'lmaganda) — liniyadan chiqasiz.';

  @override
  String get guideStep5Body => 'Faqat oflayn va faol buyurtmasiz holatda mumkin — daromadingiz hisobda saqlanadi.';

  @override
  String get statsTitle => 'Bugun · Statistika';

  @override
  String get statsCompleted => 'Bajarilgan';

  @override
  String get statsChartTitle => 'Daromad grafigi';

  @override
  String statsCompletedOrders(int count) {
    return 'Bajarilgan buyurtmalar ($count)';
  }

  @override
  String get statsNoOrders => 'Bu davrda buyurtma yo\'q';

  @override
  String get statsNoData => 'Ma\'lumot yo\'q';

  @override
  String get onlineServiceChannelName => 'Liniyada';

  @override
  String get onlineServiceChannelDesc => 'Haydovchi liniyada — buyurtma kutilmoqda';

  @override
  String get onlineServiceNotifTitle => 'Liniyadasiz';

  @override
  String get onlineServiceNotifText => 'Buyurtma kutilmoqda';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl(): super('uz_Cyrl');

  @override
  String get appName => 'Бешариқ Ҳайдовчи';

  @override
  String get noInternetConnection => 'Интернет алоқаси йўқ';

  @override
  String get homeGpsRequired => 'Линияга чиқиш учун GPS ёқилган бўлиши керак. Жойлашув рухсатини текширинг.';

  @override
  String get homeReconnecting => 'Қайта уланмоқда...';

  @override
  String get homeAddressSearchHint => 'Манзил қидириш...';

  @override
  String get homeAddressPinHint => 'Харитада уй манзилингизни белгиланг';

  @override
  String get homeAddressConfirm => 'Манзилни тасдиқлаш';

  @override
  String get homeAddressUnknownPoint => 'Белгиланган нуқта';

  @override
  String get navTurnLeft => 'Чапга';

  @override
  String get navTurnRight => 'Ўнгга';

  @override
  String get navTurnSharpLeft => 'Кескин чапга';

  @override
  String get navTurnSharpRight => 'Кескин ўнгга';

  @override
  String get navTurnSlightLeft => 'Бир оз чапга';

  @override
  String get navTurnSlightRight => 'Бир оз ўнгга';

  @override
  String get navTurnUturn => 'Орқага қайтинг';

  @override
  String get navTurnRoundabout => 'Айланма йўл';

  @override
  String navTurnBanner(int distance, String direction) {
    return '$distance м дан сўнг $direction';
  }

  @override
  String navSpeakTurn(int distance, String direction) {
    return '$distance метрдан сўнг $direction';
  }

  @override
  String navStraightBanner(int km) {
    return 'Тўғрига $km км';
  }

  @override
  String navSpeakStraight(int km) {
    return 'Тўғрига $km километр';
  }

  @override
  String get navTrafficLightBanner => 'Светофор';

  @override
  String get navSpeakTrafficLight => 'Олдинда назорат светофори';

  @override
  String get homeModeTitle => 'Уйга режими';

  @override
  String get homeModeSetAddressFirst => 'Аввал уй манзилини белгиланг';

  @override
  String get homeModeLabel => 'Уйга';

  @override
  String get homeModeEditAddress => 'Манзилни ўзгартириш';

  @override
  String get homeModePoolButton => 'Йўл-йўлакай буюртма олиш';

  @override
  String get homeModeToggleFailed => 'Режимни ўзгартириб бўлмади';

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
  String get supportTitle => 'Ёрдам';

  @override
  String get supportProfileSub => 'Саволлар ва тез ёрдам';

  @override
  String get supportNewRequest => 'Янги мурожаат';

  @override
  String get supportHistoryEmpty => 'Ҳали мурожаатлар йўқ';

  @override
  String get supportHistoryEmptySub => 'Саволингиз бўлса, пастдаги тугма орқали мурожаат қилинг';

  @override
  String get supportAiTopic => 'Эркин суҳбат (АИ)';

  @override
  String get supportMenuHeadline => 'Сизга қандай ёрдам бера оламиз?';

  @override
  String get supportMenuSub => 'Тайёр саволлардан бирини танланг ёки АИ ёрдамчига мурожаат қилинг';

  @override
  String get supportAskQuestion => 'Саволим бор';

  @override
  String get supportInputHint => 'Саволингизни ёзинг…';

  @override
  String get supportEscalatedBanner => 'Бу суҳбат администраторга юборилди — тез орада сиз билан боғланишади.';

  @override
  String get supportStatusOpen => 'Очиқ';

  @override
  String get supportStatusEscalated => 'Админга юборилган';

  @override
  String get supportStatusResolved => 'Ечилган';

  @override
  String get supportSenderAdmin => 'Администратор';

  @override
  String get supportSenderAi => 'АИ ёрдамчи';

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
  String get parcelAvailableTitle => 'Мавжуд доставкалар';

  @override
  String get parcelMyTitle => 'Менинг доставкаларим';

  @override
  String get parcelNoAvailable => 'Ҳозирча доставка йўқ';

  @override
  String get parcelNoActive => 'Фаол доставка йўқ';

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

  @override
  String get vertFood => 'Овқат';

  @override
  String get labelKitchen => 'Ошхона';

  @override
  String get labelCustomer => 'Мижоз';

  @override
  String get labelPassenger => 'Йўловчи';

  @override
  String minutesValue(int min) {
    return '$min дақиқа';
  }

  @override
  String get cancelReasonVehicle => 'Машина билан боғлиқ муаммо';

  @override
  String get cancelReasonTooFar => 'Масофа жуда узоқ';

  @override
  String get cancelReasonCannotReach => 'Мижоз билан боғлана олмадим';

  @override
  String get cancelReasonNotAtAddress => 'Мижоз манзилда топилмади';

  @override
  String get cancelReasonOther => 'Бошқа сабаб';

  @override
  String get cancelReasonTitleCancel => 'Бекор қилиш сабаби';

  @override
  String get cancelReasonTitleDecline => 'Воз кечиш сабаби';

  @override
  String get cancelReasonHint => 'Сабабни танланг. Бекор қилиш учун балансингиздан жарима ечилади.';

  @override
  String get cancelReasonNoteLabel => 'Сабабни ёзинг';

  @override
  String get cancelReasonSubmitDecline => 'Воз кечиш';

  @override
  String get homeOrderGone => 'Буюртма энди мавжуд эмас';

  @override
  String get homeOrderCancelled => 'Буюртма бекор қилинди';

  @override
  String get homeNoPhone => 'Рақам мавжуд эмас';

  @override
  String get homeDialerFailed => 'Телефон иловаси очилмади';

  @override
  String get homeActionFailed => 'Амални бажариб бўлмади';

  @override
  String get homeCancelledOfferedToOther => 'Буюртма бошқа курьерга таклиф қилинади';

  @override
  String get homeZeroBalance => 'Балансингиз 0. Линияга чиқиш учун ҳисобни тўлдиринг.';

  @override
  String get homeGenericError => 'Хатолик';

  @override
  String get driverBlockedTitle => 'Вақтинча блокландингиз';

  @override
  String get driverBlockedNoReason => 'Администратор сабабини кўрсатмаган.';

  @override
  String get driverBlockedUntilLabel => 'Қолган вақт';

  @override
  String driverBlockedDaysHours(int days, int hours) {
    return '$days кун $hours соат';
  }

  @override
  String driverBlockedHoursMinutes(int hours, int min) {
    return '$hours соат $min дақиқа';
  }

  @override
  String get driverBlockedOfficeNote => 'Дарҳол блокдан чиқиш учун офисга келиб жарима тўланг — администратор сизни дарҳол блокдан чиқаради.';

  @override
  String get driverBlockedClose => 'Ёпиш';

  @override
  String get homeNewOrder => 'Янги буюртма';

  @override
  String get homeTapToDismiss => 'Бекор қилиш учун босинг';

  @override
  String get homeDistance => 'Масофа';

  @override
  String get homePrice => 'Нарх';

  @override
  String homePickupEarningLine(String pickup, String amount) {
    return '$pickup · улуш +$amount сўм';
  }

  @override
  String get homeTakeOrder => 'Буюртмани олиш';

  @override
  String get homeCashPayment => 'Нақд тўлов';

  @override
  String get homeCollectFromCustomer => 'Мижоздан оласиз';

  @override
  String get homePayKitchen => 'Ошхонага тўлайсиз';

  @override
  String get homeYourEarning => 'Даромадингиз';

  @override
  String get homeServiceFeeBalance => 'Хизмат ҳақи (балансдан)';

  @override
  String get homeOrderNotTaken => 'Буюртма олинмади';

  @override
  String get walletTitle => 'Ҳисобим';

  @override
  String get homeTodayCard => 'Бугун';

  @override
  String homeTodayCount(int count) {
    return '$count та заказ';
  }

  @override
  String get homeFinishWork => 'Ишни якунлаш';

  @override
  String get homeGoOnline => 'Линияга чиқиш';

  @override
  String get homeKitchenPicked => 'ОШХОНА · ОЛИНДИ';

  @override
  String get homeKitchenToPickup => 'ОШХОНА · ОЛИБ КЕТИШ';

  @override
  String get homeCustomerAddress => 'МИЖОЗ МАНЗИЛИ';

  @override
  String get homeCancelShort => 'Бекор';

  @override
  String get homePreparingBanner => 'Ошхонада тайёрланмоқда — тайёр бўлганда олинг';

  @override
  String get actionArrived => 'Етиб келдим';

  @override
  String get actionSetOff => 'Йўлга чиқиш';

  @override
  String get actionFinishTrip => 'Сафарни якунлаш';

  @override
  String get actionPickedOrder => 'Буюртмани олдим';

  @override
  String get actionDelivered => 'Етказилди';

  @override
  String get actionPreparing => 'Тайёрланмоқда…';

  @override
  String get actionPickedParcel => 'Даставкани олдим';

  @override
  String get homeCashToKitchen => 'Ошхонага нақд';

  @override
  String get homeToSender => 'Жўнатувчигача';

  @override
  String get homeRecipientCall => 'Қабул қилувчи · қўнғироқ';

  @override
  String get homeRecipient => 'Қабул қилувчи';

  @override
  String get homeToCustomer => 'Мижозгача';

  @override
  String get homeWaiting => 'Кутиш';

  @override
  String get homeStart => 'Бошлаш';

  @override
  String get homeWaitingStop => 'Кутяпти — тўхтатиш';

  @override
  String get homePaidWait => 'Пулли кутиш';

  @override
  String get homeFreeWait => 'Бепул кутиш';

  @override
  String get statusTaxiAccepted => 'Мижоз олдига боринг';

  @override
  String get statusTaxiArrived => 'Йўловчини кутинг';

  @override
  String get statusTaxiInProgress => 'Манзилга йўлдасиз';

  @override
  String get statusFoodPending => 'Ошхона тасдиғи кутилмоқда';

  @override
  String get statusFoodAccepted => 'Ошхонага боринг · тайёрланмоқда';

  @override
  String get statusFoodReady => 'Буюртма тайёр · олинг';

  @override
  String get statusFoodPicked => 'Мижозга етказинг';

  @override
  String get statusParcelAccepted => 'Жўнатувчига боринг';

  @override
  String get statusParcelArrived => 'Посилкани олинг';

  @override
  String get statusParcelPicked => 'Йўлга чиқинг';

  @override
  String get statusParcelTransit => 'Қабул қилувчига йўлдасиз';

  @override
  String get summaryFoodTitle => 'Буюртма етказилди';

  @override
  String get summaryTaxiTitle => 'Сафар якунланди';

  @override
  String get summaryParcelTitle => 'Доставка якунланди';

  @override
  String get sumKitchenCash => 'Ошхонага тўланг (нақд)';

  @override
  String get sumDeliveryEarning => 'Даромадингиз (етказиш)';

  @override
  String get sumTaxiFare => 'Сафар нархи';

  @override
  String get sumPickupSurcharge => 'Олиб кетиш устамаси';

  @override
  String get sumDistance => 'Юрилган масофа';

  @override
  String get sumTripTime => 'Сафар вақти';

  @override
  String get sumParcelFare => 'Доставка нархи';

  @override
  String get sumSize => 'Ўлчам';

  @override
  String get sumTimeLabel => 'Вақт';

  @override
  String get collectFromPassenger => 'Йўловчидан олинг';

  @override
  String get collectFromCustomer => 'Мижоздан олинг';

  @override
  String get doneButton => 'Бажарилди';

  @override
  String get sizeSmall => 'Кичик';

  @override
  String get sizeLarge => 'Катта';

  @override
  String get sizeMedium => 'Ўрта';

  @override
  String get walletBalancePrefix => 'Жорий баланс';

  @override
  String get periodDaily => 'Кунлик';

  @override
  String get periodWeekly => 'Ҳафталик';

  @override
  String get periodMonthly => 'Ойлик';

  @override
  String get balanceTopupHistory => 'Тўлдириш тарихи';

  @override
  String get balanceNoTopups => 'Бу даврда тўлдириш бўлмаган';

  @override
  String get balanceCurrent => 'Жорий баланс';

  @override
  String get balanceLow => 'Кам';

  @override
  String get balanceCanAccept => 'Буюртмаларни қабул қилишингиз мумкин';

  @override
  String get balanceMustTopup => 'Буюртма олиш учун ҳисобни тўлдиринг';

  @override
  String get balanceSupportNote => 'Ҳисобни тўлдириш учун қўллаб-қувватлаш хизматига мурожаат қилинг ёки офисга ташриф буюринг.';

  @override
  String get msgTitle => 'Хабарлар';

  @override
  String get msgRefresh => 'Янгилаш';

  @override
  String get msgEmptyTitle => 'Ҳозирча хабар йўқ';

  @override
  String get msgEmptySubtitle => 'Админ хабарлари шу ерда кўринади';

  @override
  String get dayToday => 'Бугун';

  @override
  String get dayYesterday => 'Кеча';

  @override
  String get msgToYou => 'Сизга';

  @override
  String get msgAnnouncement => 'Эълон';

  @override
  String get msgNewBadge => 'Янги';

  @override
  String get navDeliverToAddress => 'Манзилга етказиш';

  @override
  String get navGoPickupCustomer => 'Мижозни олиб кетишга';

  @override
  String navEtaChip(String min, String km) {
    return '~$min дақ · $km км';
  }

  @override
  String get poolTitle => 'Бўш буюртмалар';

  @override
  String get poolEmpty => 'Ҳозирча бўш буюртма йўқ';

  @override
  String get poolLoading => 'Юкланмоқда…';

  @override
  String get poolTake => 'Олиш';

  @override
  String get tripChatNetworkError => 'Тармоқ хатоси — хабар юборилмади, қайта уринг';

  @override
  String get tripChatEnded => 'Бу суҳбатга ҳозир ёзиб бўлмайди';

  @override
  String get tripChatSendFailed => 'Хабар юборилмади, қайта уринг';

  @override
  String get tripChatCallTooltip => 'Қўнғироқ';

  @override
  String get tripChatConnecting => 'алоқа кутилмоқда…';

  @override
  String get tripChatLabel => 'суҳбат';

  @override
  String get tripChatOffline => 'Интернет алоқаси йўқ — қайта уланмоқда…';

  @override
  String get tripChatEmptyTitle => 'Ҳали хабар йўқ';

  @override
  String get tripChatEmptySubtitle => 'Биринчи бўлиб ёзинг 👋';

  @override
  String get profileTitle => 'Созламалар';

  @override
  String get profileAccountSection => 'Ҳисоб';

  @override
  String get profileMyInfo => 'Маълумотларим';

  @override
  String get profileMyInfoSub => 'Ф.И.Ш, ёш, телефон';

  @override
  String get profileMyCar => 'Менинг машинам';

  @override
  String get profileMyCarSub => 'Автомобиль ва гувоҳнома';

  @override
  String get profileTariffs => 'Тарифлар ва даромад';

  @override
  String get profileTariffsSub => 'Бугунги ва умумий даромад';

  @override
  String get profileSettingsSection => 'Созламалар';

  @override
  String get profileSoundLang => 'Овоз ва тил';

  @override
  String get profileSoundLangSub => 'Сигнал овози, илова тили';

  @override
  String get profileGuide => 'Йўриқнома';

  @override
  String get profileGuideSub => 'Иловадан қандай фойдаланиш';

  @override
  String get profileExitApp => 'Иловадан чиқиш';

  @override
  String get profileLogout => 'Ҳисобдан чиқиш';

  @override
  String get profileExitHintOnline => 'Аввал «Ишни якунлаш»ни босинг — линияда туриб иловани ёпиб бўлмайди.';

  @override
  String get profileExitHintActive => 'Фаол буюртмангиз бор — якунламагунча илова ёпилмайди.';

  @override
  String get profileCannotExitOnline => 'Линиядасиз — аввал ишни якунланг.';

  @override
  String get profileCannotExitActive => 'Фаол буюртмангиз бор.';

  @override
  String get profileLogoutDialogContent => 'Ҳисобингиздан чиқмоқчимисиз? Қайта кириш учун администратор берган 8 хонали код керак бўлади.';

  @override
  String get profileYesExit => 'Ҳа, чиқиш';

  @override
  String get profileOnlineBadge => 'Линияда';

  @override
  String get profileOfflineBadge => 'Офлайн';

  @override
  String get profilePersonalInfo => 'Шахсий маълумотлар';

  @override
  String get profileFullName => 'Ф.И.Ш';

  @override
  String get profileAge => 'Ёши';

  @override
  String profileAgeValue(String age) {
    return '$age ёш';
  }

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileInfoHint => 'Маълумотларни ўзгартириш учун администраторга мурожаат қилинг.';

  @override
  String profileCarYear(String year) {
    return '$year-йил';
  }

  @override
  String get profileDocuments => 'Ҳужжатлар';

  @override
  String get profileLicense => 'Ҳайдовчилик гувоҳномаси';

  @override
  String get profileTodayEarning => 'Бугунги даромад';

  @override
  String get profileTotalEarning => 'Умумий даромад';

  @override
  String get profileByRoutes => 'Йўналишлар бўйича';

  @override
  String get profilePaymentNote => 'Тўлов тури: нақд. Комиссия тарифи администратор томонидан белгиланади.';

  @override
  String get profileNotifications => 'Билдиришномалар';

  @override
  String get profileOrderSound => 'Буюртма сигнали овози';

  @override
  String get profileOrderSoundSub => 'Янги буюртма келганда овоз чиқади';

  @override
  String get profileLanguageSection => 'Тил';

  @override
  String get profileAppLanguage => 'Илова тили';

  @override
  String get guideStep1Body => 'Пастдаги тугмани ўнгга суринг — автомобиль белгиси тилло рангга ўтади ва буюртмалар кела бошлайди.';

  @override
  String get guideStep2Body => 'Буюртма келганда овоз ва тебраниш бўлади; 20 сония ичида қабул қилинг ёки ўтказиб юборинг.';

  @override
  String get guideStep3Body => 'Ҳеч ким олмаган буюртмалар рўйхатда туради — хаританинг ўнг юқорисидаги тугма орқали очинг.';

  @override
  String get guideStep4Body => 'Тугмани чапга суринг (фаол буюртма бўлмаганда) — линиядан чиқасиз.';

  @override
  String get guideStep5Body => 'Фақат офлайн ва фаол буюртмасиз ҳолатда мумкин — даромадингиз ҳисобда сақланади.';

  @override
  String get statsTitle => 'Бугун · Статистика';

  @override
  String get statsCompleted => 'Бажарилган';

  @override
  String get statsChartTitle => 'Даромад графиги';

  @override
  String statsCompletedOrders(int count) {
    return 'Бажарилган буюртмалар ($count)';
  }

  @override
  String get statsNoOrders => 'Бу даврда буюртма йўқ';

  @override
  String get statsNoData => 'Маълумот йўқ';

  @override
  String get onlineServiceChannelName => 'Линияда';

  @override
  String get onlineServiceChannelDesc => 'Ҳайдовчи линияда — буюртма кутилмоқда';

  @override
  String get onlineServiceNotifTitle => 'Линиядасиз';

  @override
  String get onlineServiceNotifText => 'Буюртма кутилмоқда';
}
