import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Бешарык Водитель';

  @override
  String get language => 'Язык';

  @override
  String get logout => 'Выход';

  @override
  String get loginTitle => 'Вход для водителя';

  @override
  String get loginSubtitle => 'Введите номер телефона для продолжения';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get otpTitle => 'Код подтверждения';

  @override
  String otpSubtitle(String phone) {
    return 'Введите код, отправленный на $phone';
  }

  @override
  String get otpLabel => 'Код';

  @override
  String get verify => 'Подтвердить';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String devCodeHint(String code) {
    return 'Тестовый режим — код: $code';
  }

  @override
  String get online => 'Онлайн';

  @override
  String get offline => 'Офлайн';

  @override
  String get offlineHint => 'Выйдите в онлайн, чтобы видеть заказы';

  @override
  String get availableTitle => 'Доступные заказы';

  @override
  String get myDeliveriesTitle => 'Мои доставки';

  @override
  String get noAvailable => 'Пока нет заказов';

  @override
  String get noDeliveries => 'Нет активных доставок';

  @override
  String get accept => 'Принять';

  @override
  String get markPicked => 'Забрал';

  @override
  String get markDelivered => 'Доставил';

  @override
  String get deliverTo => 'Адрес';

  @override
  String orderNo(String no) {
    return 'Заказ #$no';
  }

  @override
  String priceSom(String amount) {
    return '$amount сум';
  }

  @override
  String get statusAssigned => 'Назначен вам';

  @override
  String get statusPickedUp => 'В пути';

  @override
  String get earningsTitle => 'Мой доход';

  @override
  String get earningsToday => 'Сегодня';

  @override
  String get earningsTotal => 'Всего';

  @override
  String deliveriesCount(int count) {
    return '$count доставок';
  }

  @override
  String get yourEarning => 'Доход';

  @override
  String get deliveryTab => 'Доставка';

  @override
  String get taxiTab => 'Такси';

  @override
  String get taxiAvailableTitle => 'Доступные поездки';

  @override
  String get taxiMyTripsTitle => 'Мои поездки';

  @override
  String get taxiNoAvailable => 'Поездок пока нет';

  @override
  String get taxiNoActive => 'Нет активных поездок';

  @override
  String get taxiStart => 'Пассажир в машине';

  @override
  String get taxiComplete => 'Завершить';

  @override
  String get taxiCompleteTitle => 'Завершение поездки';

  @override
  String get taxiDistanceKm => 'Расстояние (км)';

  @override
  String get taxiWaitMinutes => 'Ожидание (мин)';

  @override
  String get taxiMeteredBadge => 'Без адреса';

  @override
  String get taxiMeteredFareHint => 'Цена рассчитывается в конце';

  @override
  String get cancel => 'Отмена';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatInputHint => 'Напишите сообщение…';

  @override
  String get chatEmpty => 'Сообщений пока нет. Начните чат.';

  @override
  String get chatGreetingNote => 'Первое сообщение начинается с «Ассалому алайкум,»';

  @override
  String get chatYou => 'Вы';

  @override
  String get chatParty => 'Клиент';

  @override
  String get supportTitle => 'Поддержка';

  @override
  String get supportProfileSub => 'Вопросы и быстрая помощь';

  @override
  String get supportNewRequest => 'Новое обращение';

  @override
  String get supportHistoryEmpty => 'Обращений пока нет';

  @override
  String get supportHistoryEmptySub => 'Если есть вопрос, обратитесь через кнопку внизу';

  @override
  String get supportAiTopic => 'Свободный чат (ИИ)';

  @override
  String get supportMenuHeadline => 'Чем мы можем вам помочь?';

  @override
  String get supportMenuSub => 'Выберите готовый вопрос или обратитесь к ИИ-помощнику';

  @override
  String get supportAskQuestion => 'У меня есть вопрос';

  @override
  String get supportInputHint => 'Напишите ваш вопрос…';

  @override
  String get supportEscalatedBanner => 'Этот чат передан администратору — с вами скоро свяжутся.';

  @override
  String get supportStatusOpen => 'Открыт';

  @override
  String get supportStatusEscalated => 'Передан админу';

  @override
  String get supportStatusResolved => 'Решён';

  @override
  String get supportSenderAdmin => 'Администратор';

  @override
  String get supportSenderAi => 'ИИ-помощник';

  @override
  String taxiTripNo(String no) {
    return 'Поездка #$no';
  }

  @override
  String taxiKm(String km) {
    return '$km км';
  }

  @override
  String get taxiStatusAccepted => 'Принята';

  @override
  String get taxiStatusInProgress => 'В пути';

  @override
  String get parcelTab => 'Доставка';

  @override
  String get parcelAvailableTitle => 'Доступные доставки';

  @override
  String get parcelMyTitle => 'Мои доставки';

  @override
  String get parcelNoAvailable => 'Доставок пока нет';

  @override
  String get parcelNoActive => 'Нет активных доставок';

  @override
  String parcelNo(String no) {
    return 'Доставка #$no';
  }

  @override
  String get parcelStatusPickedUp => 'В пути';

  @override
  String get errorInvalidPhone => 'Неверный номер телефона (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Неверный код или истёк срок действия';

  @override
  String get errorGeneric => 'Произошла ошибка. Попробуйте снова.';

  @override
  String get errorNetwork => 'Нет подключения к интернету';

  @override
  String get retry => 'Повторить';

  @override
  String get vertFood => 'Еда';

  @override
  String get labelKitchen => 'Кухня';

  @override
  String get labelCustomer => 'Клиент';

  @override
  String get labelPassenger => 'Пассажир';

  @override
  String minutesValue(int min) {
    return '$min мин';
  }

  @override
  String get cancelReasonVehicle => 'Проблема с автомобилем';

  @override
  String get cancelReasonTooFar => 'Слишком далеко';

  @override
  String get cancelReasonCannotReach => 'Не смог связаться с клиентом';

  @override
  String get cancelReasonNotAtAddress => 'Клиента нет по адресу';

  @override
  String get cancelReasonOther => 'Другая причина';

  @override
  String get cancelReasonTitleCancel => 'Причина отмены';

  @override
  String get cancelReasonTitleDecline => 'Причина отказа';

  @override
  String get cancelReasonHint => 'Выберите причину. За отмену с вашего баланса будет списан штраф.';

  @override
  String get cancelReasonNoteLabel => 'Опишите причину';

  @override
  String get cancelReasonSubmitDecline => 'Отказаться';

  @override
  String get homeOrderGone => 'Заказ больше недоступен';

  @override
  String get homeOrderCancelled => 'Заказ отменён';

  @override
  String get homeNoPhone => 'Номер недоступен';

  @override
  String get homeDialerFailed => 'Не удалось открыть приложение телефона';

  @override
  String get homeActionFailed => 'Не удалось выполнить действие';

  @override
  String get homeCancelledOfferedToOther => 'Заказ будет предложен другому курьеру';

  @override
  String get homeZeroBalance => 'Ваш баланс 0. Пополните счёт, чтобы выйти на линию.';

  @override
  String get homeGenericError => 'Ошибка';

  @override
  String get driverBlockedTitle => 'Вы временно заблокированы';

  @override
  String get driverBlockedNoReason => 'Администратор не указал причину.';

  @override
  String get driverBlockedUntilLabel => 'Осталось времени';

  @override
  String driverBlockedDaysHours(int days, int hours) {
    return '$days дн $hours ч';
  }

  @override
  String driverBlockedHoursMinutes(int hours, int min) {
    return '$hours ч $min мин';
  }

  @override
  String get driverBlockedOfficeNote => 'Чтобы разблокироваться немедленно, приезжайте в офис и оплатите штраф — администратор сразу снимет блокировку.';

  @override
  String get driverBlockedClose => 'Закрыть';

  @override
  String get homeNewOrder => 'Новый заказ';

  @override
  String get homeTapToDismiss => 'Нажмите, чтобы закрыть';

  @override
  String get homeDistance => 'Расстояние';

  @override
  String get homePrice => 'Цена';

  @override
  String homePickupEarningLine(String pickup, String amount) {
    return '$pickup · доля +$amount сум';
  }

  @override
  String get homeTakeOrder => 'Принять заказ';

  @override
  String get homeCashPayment => 'Наличный расчёт';

  @override
  String get homeCollectFromCustomer => 'Получаете от клиента';

  @override
  String get homePayKitchen => 'Платите кухне';

  @override
  String get homeYourEarning => 'Ваш доход';

  @override
  String get homeServiceFeeBalance => 'Сервисный сбор (с баланса)';

  @override
  String get homeOrderNotTaken => 'Заказ не принят';

  @override
  String get walletTitle => 'Мой счёт';

  @override
  String get homeTodayCard => 'Сегодня';

  @override
  String homeTodayCount(int count) {
    return '$count заказ(ов)';
  }

  @override
  String get homeFinishWork => 'Завершить работу';

  @override
  String get homeGoOnline => 'Выйти на линию';

  @override
  String get homeKitchenPicked => 'КУХНЯ · ЗАБРАНО';

  @override
  String get homeKitchenToPickup => 'КУХНЯ · ЗАБРАТЬ';

  @override
  String get homeCustomerAddress => 'АДРЕС КЛИЕНТА';

  @override
  String get homeCancelShort => 'Отмена';

  @override
  String get homePreparingBanner => 'Готовится на кухне — заберите, когда будет готово';

  @override
  String get actionArrived => 'Я прибыл';

  @override
  String get actionSetOff => 'Отправиться в путь';

  @override
  String get actionFinishTrip => 'Завершить поездку';

  @override
  String get actionPickedOrder => 'Я забрал заказ';

  @override
  String get actionDelivered => 'Доставлено';

  @override
  String get actionPreparing => 'Готовится…';

  @override
  String get actionPickedParcel => 'Я забрал посылку';

  @override
  String get homeCashToKitchen => 'Наличными на кухню';

  @override
  String get homeToSender => 'До отправителя';

  @override
  String get homeRecipientCall => 'Получатель · звонок';

  @override
  String get homeRecipient => 'Получатель';

  @override
  String get homeToCustomer => 'До клиента';

  @override
  String get homeWaiting => 'Ожидание';

  @override
  String get homeStart => 'Начать';

  @override
  String get homeWaitingStop => 'Ожидает — остановить';

  @override
  String get homePaidWait => 'Платное ожидание';

  @override
  String get homeFreeWait => 'Бесплатное ожидание';

  @override
  String get statusTaxiAccepted => 'Езжайте к клиенту';

  @override
  String get statusTaxiArrived => 'Ожидайте пассажира';

  @override
  String get statusTaxiInProgress => 'В пути к месту назначения';

  @override
  String get statusFoodPending => 'Ожидается подтверждение кухни';

  @override
  String get statusFoodAccepted => 'Езжайте на кухню · готовится';

  @override
  String get statusFoodReady => 'Заказ готов · заберите';

  @override
  String get statusFoodPicked => 'Доставьте клиенту';

  @override
  String get statusParcelAccepted => 'Езжайте к отправителю';

  @override
  String get statusParcelArrived => 'Заберите посылку';

  @override
  String get statusParcelPicked => 'Отправляйтесь в путь';

  @override
  String get statusParcelTransit => 'В пути к получателю';

  @override
  String get summaryFoodTitle => 'Заказ доставлен';

  @override
  String get summaryTaxiTitle => 'Поездка завершена';

  @override
  String get summaryParcelTitle => 'Доставка завершена';

  @override
  String get sumKitchenCash => 'Оплатите кухне (наличными)';

  @override
  String get sumDeliveryEarning => 'Ваш доход (доставка)';

  @override
  String get sumTaxiFare => 'Стоимость поездки';

  @override
  String get sumPickupSurcharge => 'Надбавка за подачу';

  @override
  String get sumDistance => 'Пройденное расстояние';

  @override
  String get sumTripTime => 'Время поездки';

  @override
  String get sumParcelFare => 'Стоимость доставки';

  @override
  String get sumSize => 'Размер';

  @override
  String get sumTimeLabel => 'Время';

  @override
  String get collectFromPassenger => 'Получите с пассажира';

  @override
  String get collectFromCustomer => 'Получите с клиента';

  @override
  String get doneButton => 'Готово';

  @override
  String get sizeSmall => 'Маленький';

  @override
  String get sizeLarge => 'Большой';

  @override
  String get sizeMedium => 'Средний';

  @override
  String get walletBalancePrefix => 'Текущий баланс';

  @override
  String get periodDaily => 'За день';

  @override
  String get periodWeekly => 'За неделю';

  @override
  String get periodMonthly => 'За месяц';

  @override
  String get balanceTopupHistory => 'История пополнений';

  @override
  String get balanceNoTopups => 'За этот период пополнений не было';

  @override
  String get balanceCurrent => 'Текущий баланс';

  @override
  String get balanceLow => 'Мало';

  @override
  String get balanceCanAccept => 'Вы можете принимать заказы';

  @override
  String get balanceMustTopup => 'Пополните счёт, чтобы принимать заказы';

  @override
  String get balanceSupportNote => 'Для пополнения счёта обратитесь в службу поддержки или посетите офис.';

  @override
  String get msgTitle => 'Сообщения';

  @override
  String get msgRefresh => 'Обновить';

  @override
  String get msgEmptyTitle => 'Сообщений пока нет';

  @override
  String get msgEmptySubtitle => 'Сообщения администратора будут здесь';

  @override
  String get dayToday => 'Сегодня';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get msgToYou => 'Вам';

  @override
  String get msgAnnouncement => 'Объявление';

  @override
  String get msgNewBadge => 'Новое';

  @override
  String get navDeliverToAddress => 'Доставить по адресу';

  @override
  String get navGoPickupCustomer => 'Забрать клиента';

  @override
  String navEtaChip(String min, String km) {
    return '~$min мин · $km км';
  }

  @override
  String get poolTitle => 'Свободные заказы';

  @override
  String get poolEmpty => 'Пока нет свободных заказов';

  @override
  String get poolLoading => 'Загрузка…';

  @override
  String get poolTake => 'Принять';

  @override
  String get tripChatNetworkError => 'Ошибка сети — сообщение не отправлено, попробуйте снова';

  @override
  String get tripChatEnded => 'В этот чат сейчас нельзя писать';

  @override
  String get tripChatSendFailed => 'Сообщение не отправлено, попробуйте снова';

  @override
  String get tripChatCallTooltip => 'Звонок';

  @override
  String get tripChatConnecting => 'подключение…';

  @override
  String get tripChatLabel => 'чат';

  @override
  String get tripChatOffline => 'Нет интернета — переподключение…';

  @override
  String get tripChatEmptyTitle => 'Сообщений пока нет';

  @override
  String get tripChatEmptySubtitle => 'Напишите первым 👋';

  @override
  String get profileTitle => 'Настройки';

  @override
  String get profileAccountSection => 'Аккаунт';

  @override
  String get profileMyInfo => 'Мои данные';

  @override
  String get profileMyInfoSub => 'ФИО, возраст, телефон';

  @override
  String get profileMyCar => 'Моя машина';

  @override
  String get profileMyCarSub => 'Автомобиль и права';

  @override
  String get profileTariffs => 'Тарифы и доход';

  @override
  String get profileTariffsSub => 'Доход за сегодня и всего';

  @override
  String get profileSettingsSection => 'Настройки';

  @override
  String get profileSoundLang => 'Звук и язык';

  @override
  String get profileSoundLangSub => 'Звук сигнала, язык приложения';

  @override
  String get profileGuide => 'Инструкция';

  @override
  String get profileGuideSub => 'Как пользоваться приложением';

  @override
  String get profileExitApp => 'Выйти из приложения';

  @override
  String get profileLogout => 'Выйти из аккаунта';

  @override
  String get profileExitHintOnline => 'Сначала нажмите «Завершить работу» — нельзя закрыть приложение на линии.';

  @override
  String get profileExitHintActive => 'У вас активный заказ — приложение не закроется, пока он не завершён.';

  @override
  String get profileCannotExitOnline => 'Вы на линии — сначала завершите работу.';

  @override
  String get profileCannotExitActive => 'У вас активный заказ.';

  @override
  String get profileLogoutDialogContent => 'Вы хотите выйти из аккаунта? Для повторного входа понадобится 8-значный код от администратора.';

  @override
  String get profileYesExit => 'Да, выйти';

  @override
  String get profileOnlineBadge => 'На линии';

  @override
  String get profileOfflineBadge => 'Офлайн';

  @override
  String get profilePersonalInfo => 'Личные данные';

  @override
  String get profileFullName => 'ФИО';

  @override
  String get profileAge => 'Возраст';

  @override
  String profileAgeValue(String age) {
    return '$age лет';
  }

  @override
  String get profilePhone => 'Телефон';

  @override
  String get profileInfoHint => 'Для изменения данных обратитесь к администратору.';

  @override
  String profileCarYear(String year) {
    return '$year г.';
  }

  @override
  String get profileDocuments => 'Документы';

  @override
  String get profileLicense => 'Водительское удостоверение';

  @override
  String get profileTodayEarning => 'Доход за сегодня';

  @override
  String get profileTotalEarning => 'Общий доход';

  @override
  String get profileByRoutes => 'По направлениям';

  @override
  String get profilePaymentNote => 'Тип оплаты: наличные. Тариф комиссии устанавливается администратором.';

  @override
  String get profileNotifications => 'Уведомления';

  @override
  String get profileOrderSound => 'Звук сигнала заказа';

  @override
  String get profileOrderSoundSub => 'Звук при поступлении нового заказа';

  @override
  String get profileLanguageSection => 'Язык';

  @override
  String get profileAppLanguage => 'Язык приложения';

  @override
  String get guideStep1Body => 'Проведите нижнюю кнопку вправо — значок машины станет золотым, и начнут поступать заказы.';

  @override
  String get guideStep2Body => 'При поступлении заказа прозвучит сигнал и вибрация; примите его в течение 20 секунд или пропустите.';

  @override
  String get guideStep3Body => 'Никем не принятые заказы остаются в списке — откройте через кнопку в правом верхнем углу карты.';

  @override
  String get guideStep4Body => 'Проведите кнопку влево (при отсутствии активного заказа) — вы выйдете с линии.';

  @override
  String get guideStep5Body => 'Возможно только офлайн и без активного заказа — ваш доход сохранится на счету.';

  @override
  String get statsTitle => 'Сегодня · Статистика';

  @override
  String get statsCompleted => 'Выполнено';

  @override
  String get statsChartTitle => 'График дохода';

  @override
  String statsCompletedOrders(int count) {
    return 'Выполненные заказы ($count)';
  }

  @override
  String get statsNoOrders => 'За этот период заказов нет';

  @override
  String get statsNoData => 'Нет данных';

  @override
  String get onlineServiceChannelName => 'На линии';

  @override
  String get onlineServiceChannelDesc => 'Водитель на линии — ожидание заказа';

  @override
  String get onlineServiceNotifTitle => 'Вы не на линии';

  @override
  String get onlineServiceNotifText => 'Ожидание заказа';
}
