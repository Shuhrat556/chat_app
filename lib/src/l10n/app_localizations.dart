import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('uz'),
    Locale('ru'),
    Locale('tg'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'welcome': 'Welcome',
      'sign_in_subtitle': 'Sign in with email',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Sign in',
      'sign_up': 'Sign up',
      'error': 'Error',
      'required_email': 'Enter email',
      'invalid_email': 'Invalid email',
      'required_password': 'Enter password',
      'min_password': 'At least 8 characters',
      'signup_title': 'Create account',
      'signup_subtitle': 'Enter your profile details',
      'username': 'Username',
      'first_name': 'First name',
      'last_name': 'Last name',
      'birth_date': 'Birth date (YYYY-MM-DD)',
      'photo_url': 'Profile photo URL (optional)',
      'bio': 'Bio / About (optional)',
      'required_username': 'Enter username',
      'min_username': 'At least 3 characters',
      'no_spaces': 'No spaces allowed',
      'required_first_name': 'Enter first name',
      'required_last_name': 'Enter last name',
      'min_two_chars': 'At least 2 characters',
      'required_birth': 'Enter birth date',
      'invalid_date': 'Invalid date format',
      'future_date': 'Cannot be in the future',
      'back_to_sign_in': 'Back to sign in',
      'not_signed_in': 'You are not signed in',
      'no_users': 'No other users yet',
      'loading': 'Loading...',
      'chats_title': 'Chats',
      'chat_with': 'Chat',
      'user_not_found': 'User not found',
      'online': 'Online',
      'input_hint': 'Type a message...',
      'no_messages': 'No messages yet',
    },
    'uz': {
      'welcome': 'Xush kelibsiz',
      'sign_in_subtitle': 'Email bilan tizimga kiring',
      'email': 'Email',
      'password': 'Parol',
      'sign_in': 'Kirish',
      'sign_up': "Ro'yxatdan o'tish",
      'error': 'Xatolik',
      'required_email': 'Email kiriting',
      'invalid_email': 'Noto‘g‘ri email',
      'required_password': 'Parol kiriting',
      'min_password': 'Kamida 8 ta belgi',
      'signup_title': "Ro'yxatdan o'tish",
      'signup_subtitle': 'Profil maʼlumotlaringizni kiriting',
      'username': 'Username',
      'first_name': 'Ism',
      'last_name': 'Familiya',
      'birth_date': 'Tug‘ilgan sana (YYYY-MM-DD)',
      'photo_url': 'Profil rasmi URL (ixtiyoriy)',
      'bio': 'Bio / About (ixtiyoriy)',
      'required_username': 'Username kiriting',
      'min_username': 'Kamida 3 ta belgi',
      'no_spaces': "Bo'shliq bo'lmasin",
      'required_first_name': 'Ism kiriting',
      'required_last_name': 'Familiya kiriting',
      'min_two_chars': 'Kamida 2 ta belgi',
      'required_birth': 'Tug‘ilgan sanani kiriting',
      'invalid_date': 'Sana formati noto‘g‘ri',
      'future_date': 'Kelajak sanasi bo‘lishi mumkin emas',
      'back_to_sign_in': 'Kirishga qaytish',
      'not_signed_in': 'Tizimga kirmagansiz',
      'no_users': 'Hozircha boshqa foydalanuvchi yo‘q',
      'loading': 'Yuklanmoqda...',
      'chats_title': 'Chatlar',
      'chat_with': 'Chat',
      'user_not_found': 'Foydalanuvchi topilmadi',
      'online': 'Onlayn',
      'input_hint': 'Xabar yozing...',
      'no_messages': 'Hozircha xabarlar yo‘q',
    },
    'ru': {
      'welcome': 'Добро пожаловать',
      'sign_in_subtitle': 'Войдите по email',
      'email': 'Email',
      'password': 'Пароль',
      'sign_in': 'Войти',
      'sign_up': 'Регистрация',
      'error': 'Ошибка',
      'required_email': 'Введите email',
      'invalid_email': 'Неверный email',
      'required_password': 'Введите пароль',
      'min_password': 'Минимум 8 символов',
      'signup_title': 'Регистрация',
      'signup_subtitle': 'Заполните профиль',
      'username': 'Юзернейм',
      'first_name': 'Имя',
      'last_name': 'Фамилия',
      'birth_date': 'Дата рождения (ГГГГ-ММ-ДД)',
      'photo_url': 'URL фото профиля (опционально)',
      'bio': 'Био / О себе (опционально)',
      'required_username': 'Введите юзернейм',
      'min_username': 'Минимум 3 символа',
      'no_spaces': 'Без пробелов',
      'required_first_name': 'Введите имя',
      'required_last_name': 'Введите фамилию',
      'min_two_chars': 'Минимум 2 символа',
      'required_birth': 'Введите дату рождения',
      'invalid_date': 'Неверный формат даты',
      'future_date': 'Нельзя будущую дату',
      'back_to_sign_in': 'Назад ко входу',
      'not_signed_in': 'Вы не авторизованы',
      'no_users': 'Пока нет других пользователей',
      'loading': 'Загрузка...',
      'chats_title': 'Чаты',
      'chat_with': 'Чат',
      'user_not_found': 'Пользователь не найден',
      'online': 'Онлайн',
      'input_hint': 'Напишите сообщение...',
      'no_messages': 'Пока нет сообщений',
    },
    'tg': {
      'welcome': 'Хуш омадед',
      'sign_in_subtitle': 'Бо email ворид шавед',
      'email': 'Email',
      'password': 'Парол',
      'sign_in': 'Ворид шудан',
      'sign_up': 'Бақайдгирӣ',
      'error': 'Хато',
      'required_email': 'Email ворид кунед',
      'invalid_email': 'Email нодуруст',
      'required_password': 'Парол ворид кунед',
      'min_password': 'На камтар аз 8 аломат',
      'signup_title': 'Бақайдгирӣ',
      'signup_subtitle': 'Маълумоти профилро ворид кунед',
      'username': 'Номи корбар',
      'first_name': 'Ном',
      'last_name': 'Насаб',
      'birth_date': 'Санаи таваллуд (YYYY-MM-DD)',
      'photo_url': 'URL акс (ихтиёрӣ)',
      'bio': 'Bio / Оиди худ (ихтиёрӣ)',
      'required_username': 'Номи корбар ворид кунед',
      'min_username': 'На камтар аз 3 аломат',
      'no_spaces': 'Фосила манъ аст',
      'required_first_name': 'Ном ворид кунед',
      'required_last_name': 'Насаб ворид кунед',
      'min_two_chars': 'На камтар аз 2 аломат',
      'required_birth': 'Санаи таваллуд ворид кунед',
      'invalid_date': 'Формати сана нодуруст',
      'future_date': 'Санаи оянда иҷозат нест',
      'back_to_sign_in': 'Баргаштан ба воридшавӣ',
      'not_signed_in': 'Шумо ворид нашудаед',
      'no_users': 'Ҳоло корбари дигар нест',
      'loading': 'Боргирӣ...',
      'chats_title': 'Чатҳо',
      'chat_with': 'Чат',
      'user_not_found': 'Корбар ёфт нашуд',
      'online': 'Онлайн',
      'input_hint': 'Паём нависед...',
      'no_messages': 'Ҳоло паём нест',
    },
  };

  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get welcome => _t('welcome');
  String get signInSubtitle => _t('sign_in_subtitle');
  String get email => _t('email');
  String get password => _t('password');
  String get signIn => _t('sign_in');
  String get signUp => _t('sign_up');
  String get error => _t('error');
  String get requiredEmail => _t('required_email');
  String get invalidEmail => _t('invalid_email');
  String get requiredPassword => _t('required_password');
  String get minPassword => _t('min_password');
  String get signupTitle => _t('signup_title');
  String get signupSubtitle => _t('signup_subtitle');
  String get username => _t('username');
  String get firstName => _t('first_name');
  String get lastName => _t('last_name');
  String get birthDate => _t('birth_date');
  String get photoUrl => _t('photo_url');
  String get bio => _t('bio');
  String get requiredUsername => _t('required_username');
  String get minUsername => _t('min_username');
  String get noSpaces => _t('no_spaces');
  String get requiredFirstName => _t('required_first_name');
  String get requiredLastName => _t('required_last_name');
  String get minTwoChars => _t('min_two_chars');
  String get requiredBirth => _t('required_birth');
  String get invalidDate => _t('invalid_date');
  String get futureDate => _t('future_date');
  String get backToSignIn => _t('back_to_sign_in');
  String get notSignedIn => _t('not_signed_in');
  String get noUsers => _t('no_users');
  String get loading => _t('loading');
  String get chatsTitle => _t('chats_title');
  String get chatWith => _t('chat_with');
  String get userNotFound => _t('user_not_found');
  String get online => _t('online');
  String get inputHint => _t('input_hint');
  String get noMessages => _t('no_messages');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.map((e) => e.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
