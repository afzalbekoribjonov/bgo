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
}
