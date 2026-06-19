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
  String get errorInvalidPhone => 'Неверный номер телефона (+998XXXXXXXXX)';

  @override
  String get errorInvalidCode => 'Неверный код или истёк срок действия';

  @override
  String get errorGeneric => 'Произошла ошибка. Попробуйте снова.';

  @override
  String get errorNetwork => 'Нет подключения к интернету';

  @override
  String get retry => 'Повторить';
}
