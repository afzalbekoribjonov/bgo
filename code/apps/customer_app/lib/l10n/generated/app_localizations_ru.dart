import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Бешарык';

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
  String priceSom(String amount) {
    return '$amount сум';
  }

  @override
  String get emptyRestaurants => 'Пока нет ресторанов';

  @override
  String get emptyMenu => 'Меню пока пусто';

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
}
