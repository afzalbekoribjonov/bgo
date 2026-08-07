import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Бешарык';

  @override
  String get noInternetConnection => 'Нет подключения к интернету';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get chooseService => 'Выберите услугу';

  @override
  String get serviceFood => 'Еда';

  @override
  String get serviceTaxi => 'Такси';

  @override
  String get serviceDelivery => 'Доставка';

  @override
  String get language => 'Язык';

  @override
  String get loginTitle => 'Вход / Регистрация';

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
  String get telegramFreeHint => 'Получите код бесплатно через Telegram';

  @override
  String get consentTitle => 'Конфиденциальность и условия';

  @override
  String get consentBody => 'Продолжая, вы соглашаетесь с Условиями использования и Политикой конфиденциальности. Данные о местоположении используются для оказания услуги.';

  @override
  String get consentCheckbox => 'Я согласен с условиями и политикой конфиденциальности';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get logout => 'Выход';

  @override
  String get cancel => 'Отмена';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get guestUser => 'Гость';

  @override
  String get logoutConfirm => 'Выйти из аккаунта?';

  @override
  String get personalInfo => 'Личные данные';

  @override
  String get profilePhone => 'Номер телефона';

  @override
  String get errorInvalidPhone => 'Неверный номер телефона (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Неверный код или истёк срок действия';

  @override
  String get errorGeneric => 'Произошла ошибка. Попробуйте снова.';

  @override
  String get errorNetwork => 'Нет подключения к интернету';

  @override
  String get restaurantsTitle => 'Рестораны';

  @override
  String get open => 'Открыто';

  @override
  String get closed => 'Закрыто';

  @override
  String get unavailable => 'Нет в наличии';

  @override
  String get restaurantClosedBanner => 'Этот ресторан сейчас закрыт — заказы не принимаются';

  @override
  String priceSom(String amount) {
    return '$amount сум';
  }

  @override
  String get emptyRestaurants => 'Пока нет ресторанов';

  @override
  String get emptyMenu => 'Меню пока пусто';

  @override
  String get foodSearchHint => 'Поиск ресторана…';

  @override
  String get foodFilterAll => 'Все';

  @override
  String get foodFilterOpen => 'Открыто';

  @override
  String get foodFilterTop => 'Высокий рейтинг';

  @override
  String get foodPromoTitle => 'Бесплатная доставка';

  @override
  String get foodPromoSubtitle => 'На первый заказ из выбранных ресторанов';

  @override
  String get foodSectionRestaurants => 'Рестораны';

  @override
  String get restaurantsMapTitle => 'Карта ресторанов';

  @override
  String get restaurantsMapEmpty => 'Нет ресторанов с указанным расположением';

  @override
  String get foodNothingFound => 'Ничего не найдено';

  @override
  String get greetingHi => 'Привет';

  @override
  String get homeLocation => 'Бешарикский район';

  @override
  String get homePopular => 'Популярные рестораны';

  @override
  String get homeNearby => 'Ближайшие кухни';

  @override
  String get homeAllRestaurants => 'Все рестораны';

  @override
  String get homeDishes => 'Популярные блюда';

  @override
  String get homeSeeAll => 'Все';

  @override
  String get homeMarketProducts => 'Beshariq Market';

  @override
  String get homeClosedRestaurants => 'Закрытые рестораны';

  @override
  String get emptyMarketProducts => 'Пока нет товаров';

  @override
  String get homeBanner2Title => '-20% на первый заказ';

  @override
  String get homeBanner2Sub => 'Скидка для новых клиентов';

  @override
  String get homeBanner3Title => 'Быстро и горячо';

  @override
  String get homeBanner3Sub => 'Доставим в среднем за 30 минут';

  @override
  String get retry => 'Повторить';

  @override
  String get cart => 'Корзина';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get subtotalLabel => 'Блюда';

  @override
  String get deliveryFeeLabel => 'Доставка';

  @override
  String get totalLabel => 'Итого';

  @override
  String get checkoutButton => 'Оформить заказ';

  @override
  String get checkoutTitle => 'Оформление';

  @override
  String get yourOrderLabel => 'Ваш заказ';

  @override
  String get addressLabel => 'Адрес доставки';

  @override
  String get addressHint => 'Улица, дом, ориентир';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get paymentCash => 'Наличные';

  @override
  String get deliveryNote => 'Стоимость доставки добавится к заказу';

  @override
  String get placeOrder => 'Подтвердить заказ';

  @override
  String get orderPlacedTitle => 'Заказ принят';

  @override
  String get orderPlacedDesc => 'Ваш заказ отправлен в ресторан.';

  @override
  String get myOrders => 'Мои заказы';

  @override
  String get noOrders => 'Заказов пока нет';

  @override
  String orderNo(String no) {
    return 'Заказ #$no';
  }

  @override
  String get cancelOrder => 'Отменить';

  @override
  String get backToHome => 'На главную';

  @override
  String get cartUpdatedNewRestaurant => 'Корзина обновлена для нового ресторана';

  @override
  String get statusPending => 'Ожидает';

  @override
  String get statusAccepted => 'Принят';

  @override
  String get statusPreparing => 'Готовится';

  @override
  String get statusReady => 'Готово — курьер забирает';

  @override
  String get statusOnTheWay => 'В пути';

  @override
  String get statusDelivered => 'Доставлен';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String get statusFailed => 'Не выполнен';

  @override
  String get promoLabel => 'Промокод';

  @override
  String get promoHint => 'Если есть';

  @override
  String get discountLabel => 'Скидка';

  @override
  String get promoInvalid => 'Промокод недействителен';

  @override
  String get promoCheck => 'Проверить';

  @override
  String get promoNeedsCheck => 'Сначала проверьте промокод';

  @override
  String get promoApplied => 'Промокод применён';

  @override
  String get partnerTitle => 'Партнёрство';

  @override
  String get partnerBanner => 'Станьте нашим партнёром';

  @override
  String get partnerBannerSubtitle => 'Оставьте заявку как ресторан или водитель';

  @override
  String get partnerFormTitle => 'Заявка на партнёрство';

  @override
  String get partnerFullName => 'Ф.И.О.';

  @override
  String get partnerFullNameHint => 'Ваше имя и фамилия';

  @override
  String get partnerType => 'Тип партнёрства';

  @override
  String get partnerTypeRestaurant => 'Ресторан';

  @override
  String get partnerTypeDriver => 'Водитель';

  @override
  String get partnerNote => 'Примечание (необязательно)';

  @override
  String get partnerNoteHint => 'Дополнительная информация';

  @override
  String get partnerSubmit => 'Отправить заявку';

  @override
  String get partnerSubmitted => 'Ваша заявка принята';

  @override
  String get partnerMyApplications => 'Мои заявки';

  @override
  String get partnerNoApplications => 'Заявок пока нет';

  @override
  String get partnerNameRequired => 'Введите имя';

  @override
  String get partnerStatusPending => 'На рассмотрении';

  @override
  String get partnerStatusApproved => 'Одобрено';

  @override
  String get partnerStatusRejected => 'Отклонено';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileName => 'Имя и фамилия';

  @override
  String get profileNameHint => 'Введите ваше имя';

  @override
  String get profileSave => 'Сохранить';

  @override
  String get profileSaved => 'Сохранено';

  @override
  String get profileEditAction => 'Редактировать';

  @override
  String get profilePersonalSub => 'Имя и личные данные';

  @override
  String get profileAddressesSub => 'Дом, работа и сохранённые адреса';

  @override
  String get profileOrdersSub => 'История еды, такси и доставки';

  @override
  String get profileLanguageSub => 'Язык приложения';

  @override
  String get profileKitchenSub => 'Управление панелью кухни';

  @override
  String get profilePhoneLocked => 'Номер телефона привязан к аккаунту — изменить нельзя';

  @override
  String get profileNameRequired => 'Введите не менее 2 букв';

  @override
  String get profileMainSection => 'Основные данные';

  @override
  String get addressesTitle => 'Мои адреса';

  @override
  String get addressAdd => 'Добавить адрес';

  @override
  String get addressLabelField => 'Название (Дом, Работа...)';

  @override
  String get addressPickOnMap => 'Выберите адрес на карте';

  @override
  String get addressTextField => 'Полный адрес';

  @override
  String get addressDefault => 'По умолчанию';

  @override
  String get addressSetDefault => 'Сделать основным';

  @override
  String get addressDelete => 'Удалить';

  @override
  String get addressNone => 'Нет сохранённых адресов';

  @override
  String get addressDefaultBadge => 'По умолчанию';

  @override
  String get addressNew => 'Новый адрес';

  @override
  String get addressChoose => 'Выберите адрес';

  @override
  String get checkoutDeliverHere => 'Доставить на моё местоположение';

  @override
  String get checkoutGpsSelected => 'GPS-местоположение выбрано — курьер приедет сюда';

  @override
  String get taxiTitle => 'Такси';

  @override
  String get taxiFrom => 'Откуда';

  @override
  String get taxiTo => 'Куда';

  @override
  String get taxiEstimate => 'Рассчитать цену';

  @override
  String get taxiRequest => 'Вызвать такси';

  @override
  String get taxiDistance => 'Расстояние';

  @override
  String get taxiFare => 'Цена';

  @override
  String taxiKm(String km) {
    return '$km км';
  }

  @override
  String get taxiSamePoint => 'Точки отправления и назначения должны отличаться';

  @override
  String get taxiActiveTrip => 'Текущая поездка';

  @override
  String get taxiMyTrips => 'Мои поездки';

  @override
  String get taxiNoTrips => 'Поездок пока нет';

  @override
  String get taxiRequested => 'Такси вызвано';

  @override
  String get taxiCancel => 'Отменить';

  @override
  String taxiTripNo(String no) {
    return 'Поездка #$no';
  }

  @override
  String get taxiStatusPending => 'Ожидание водителя';

  @override
  String get taxiStatusAccepted => 'Водитель в пути';

  @override
  String get taxiStatusInProgress => 'В пути';

  @override
  String get taxiStatusCompleted => 'Завершена';

  @override
  String get taxiStatusCancelled => 'Отменена';

  @override
  String get taxiNoDestination => 'Вызвать без указания адреса';

  @override
  String get taxiMeteredHint => 'Цена рассчитывается в конце поездки по расстоянию';

  @override
  String get taxiMeteredBadge => 'Без адреса';

  @override
  String get mapPickTitle => 'Выберите место';

  @override
  String get mapSearchHint => 'Поиск места…';

  @override
  String get mapConfirm => 'Выбрать';

  @override
  String get mapPickedPoint => 'Место на карте';

  @override
  String get mapLocalPlace => 'Место в Бешарике';

  @override
  String get mapNoResults => 'Ничего не найдено';

  @override
  String get taxiCurrentLocation => 'Текущее местоположение';

  @override
  String taxiFareFrom(String price) {
    return 'от $price';
  }

  @override
  String get taxiSearchingCars => 'Поиск ближайших водителей…';

  @override
  String get taxiSelectFromHint => 'Откуда?';

  @override
  String get taxiSelectToHint => 'Куда?';

  @override
  String taxiDriverEta(String min) {
    return 'Водитель прибудет через ~$min мин';
  }

  @override
  String taxiArriveEta(String min) {
    return 'До места ~$min мин';
  }

  @override
  String taxiNearbyCars(String count) {
    return '$count машин поблизости';
  }

  @override
  String get rateTitle => 'Оцените поездку';

  @override
  String get rateSubtitle => 'Вам понравился сервис?';

  @override
  String get rateHint => 'Комментарий (необязательно)';

  @override
  String get rateSubmit => 'Отправить';

  @override
  String get rateSkip => 'Позже';

  @override
  String get rateThanks => 'Спасибо за оценку!';

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
  String get chatParty => 'Водитель';

  @override
  String get supportTitle => 'Поддержка';

  @override
  String get supportProfileSub => 'Вопросы и быстрая помощь';

  @override
  String get msgTitle => 'Сообщения';

  @override
  String get msgProfileSub => 'Объявления от администратора';

  @override
  String get msgRefresh => 'Обновить';

  @override
  String get msgEmptyTitle => 'Пока нет сообщений';

  @override
  String get msgEmptySubtitle => 'Сообщения администратора появятся здесь';

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
  String get parcelTitle => 'Доставка';

  @override
  String get parcelSize => 'Размер';

  @override
  String get parcelSizeSmall => 'Маленький';

  @override
  String get parcelSizeMedium => 'Средний';

  @override
  String get parcelSizeLarge => 'Большой';

  @override
  String get parcelRecipientName => 'Имя получателя';

  @override
  String get parcelRecipientPhone => 'Телефон получателя';

  @override
  String get parcelNote => 'Примечание (необязательно)';

  @override
  String get parcelSend => 'Отправить';

  @override
  String get parcelSent => 'Посылка отправлена';

  @override
  String get parcelMyParcels => 'Мои отправления';

  @override
  String get parcelNoParcels => 'Отправлений пока нет';

  @override
  String get parcelRecipientRequired => 'Нужны имя и телефон получателя';

  @override
  String parcelNo(String no) {
    return 'Отправление #$no';
  }

  @override
  String get parcelStatusPending => 'Ожидание курьера';

  @override
  String get parcelStatusAccepted => 'Курьер принял';

  @override
  String get parcelStatusPickedUp => 'В пути';

  @override
  String get parcelStatusDelivered => 'Доставлено';

  @override
  String get parcelStatusCancelled => 'Отменено';
}
