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
      'sign_in_subtitle': 'Sign in to continue',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Sign in',
      'sign_up': 'Sign up',
      'continue_with': 'Continue with',
      'google_sign_in': 'Continue with Google',
      'apple_sign_in': 'Continue with Apple',
      'error': 'Error',
      'forgot_password': 'Forgot password?',
      'reset_password': 'Reset password',
      'send_reset': 'Send reset link',
      'reset_sent': 'Password reset link sent to email',
      'required_email': 'Enter email',
      'invalid_email': 'Invalid email',
      'required_password': 'Enter password',
      'min_password': 'At least 8 characters',
      'confirm_password': 'Confirm password',
      'required_confirm_password': 'Confirm your password',
      'password_mismatch': 'Passwords do not match',
      'or': 'or',
      'no_account_prompt': 'No account yet?',
      'have_account_prompt': 'Already have an account?',
      'auth_footer': '© 2026 Chat App. All rights reserved.',
      'signup_title': 'Create account',
      'signup_subtitle': 'Create your free account',
      'username': 'Username',
      'first_name': 'First name',
      'last_name': 'Last name',
      'birth_date': 'Birth date (YYYY-MM-DD)',
      'photo_url': 'Profile photo URL (optional)',
      'bio': 'Bio / About (optional)',
      'profile_title': 'Profile',
      'profile_subtitle': 'Update your personal info',
      'save_changes': 'Save changes',
      'delete_account': 'Delete account',
      'delete_account_title': 'Delete account?',
      'delete_account_body': 'This action permanently removes your profile.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'sign_out': 'Sign out',
      'profile_updated': 'Profile updated',
      'account_deleted': 'Account deleted',
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
      'offline': 'Offline',
      'last_seen': 'Last seen',
      'input_hint': 'Type a message...',
      'no_messages': 'No messages yet',
      'settings_title': 'Settings',
      'appearance': 'Appearance',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'privacy_settings': 'Privacy',
      'read_receipts_title': 'Read receipts',
      'read_receipts_subtitle': 'Let others see when you read messages',
      'secret_chat_default_title': 'Secret timer default',
      'secret_chat_default_subtitle':
          'Use 30s timer by default for new messages',
      'sticker_pack_title': 'Sticker pack',
      'sticker_pack_subtitle': 'Manage your personal sticker pack',
      'sticker_pack_hint': 'My Stickers',
      'saved': 'Saved',
      'add_sticker': 'Add sticker',
      'no_stickers_yet': 'No stickers yet',
      'username_min_5': 'At least 5 characters',
      'username_max_20': 'At most 20 characters',
      'username_latin_only': 'Only latin letters allowed',
    },
    'uz': {
      'welcome': 'Xush kelibsiz',
      'sign_in_subtitle': 'Davom etish uchun tizimga kiring',
      'email': 'Email',
      'password': 'Parol',
      'sign_in': 'Kirish',
      'sign_up': "Ro'yxatdan o'tish",
      'continue_with': 'Davom etish',
      'google_sign_in': 'Google bilan kirish',
      'apple_sign_in': 'Apple bilan kirish',
      'error': 'Xatolik',
      'forgot_password': 'Parolni unutdingizmi?',
      'reset_password': 'Parolni tiklash',
      'send_reset': 'Tiklash havolasini yuborish',
      'reset_sent': 'Tiklash havolasi emailingizga yuborildi',
      'required_email': 'Email kiriting',
      'invalid_email': 'Noto‘g‘ri email',
      'required_password': 'Parol kiriting',
      'min_password': 'Kamida 8 ta belgi',
      'confirm_password': 'Parolni tasdiqlang',
      'required_confirm_password': 'Parolni tasdiqlang',
      'password_mismatch': 'Parollar mos kelmadi',
      'or': 'yoki',
      'no_account_prompt': "Hisobingiz yo'qmi?",
      'have_account_prompt': 'Hisobingiz bormi?',
      'auth_footer': "© 2026 Chat App. Barcha huquqlar himoyalangan.",
      'signup_title': "Ro'yxatdan o'tish",
      'signup_subtitle': "Bepul ro'yxatdan o'ting",
      'username': 'Username',
      'first_name': 'Ism',
      'last_name': 'Familiya',
      'birth_date': 'Tug‘ilgan sana (YYYY-MM-DD)',
      'photo_url': 'Profil rasmi URL (ixtiyoriy)',
      'bio': 'Bio / About (ixtiyoriy)',
      'profile_title': 'Profil',
      'profile_subtitle': 'Maʼlumotlaringizni yangilang',
      'save_changes': 'O‘zgarishlarni saqlash',
      'delete_account': 'Akkauntni o‘chirish',
      'delete_account_title': 'Akkauntni o‘chiraymi?',
      'delete_account_body': 'Bu amal profilingizni butunlay o‘chiradi.',
      'cancel': 'Bekor qilish',
      'confirm': 'Tasdiqlash',
      'sign_out': 'Chiqish',
      'profile_updated': 'Profil yangilandi',
      'account_deleted': 'Akkaunt o‘chirildi',
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
      'offline': 'Oflayn',
      'last_seen': 'Oxirgi kirishi',
      'input_hint': 'Xabar yozing...',
      'no_messages': 'Hozircha xabarlar yo‘q',
      'settings_title': 'Sozlamalar',
      'appearance': 'Ko‘rinish',
      'theme_system': 'Tizim',
      'theme_light': 'Yorug‘',
      'theme_dark': 'Qorong‘i',
      'privacy_settings': 'Maxfiylik',
      'read_receipts_title': 'O‘qilgan belgilari',
      'read_receipts_subtitle':
          'Boshqalar xabaringizni qachon o‘qiganingizni ko‘rishi mumkin',
      'secret_chat_default_title': 'Secret timer default',
      'secret_chat_default_subtitle':
          'Yangi xabarlar uchun avtomatik 30 soniya timer ishlatilsin',
      'sticker_pack_title': 'Sticker pack',
      'sticker_pack_subtitle': 'Shaxsiy sticker pack boshqaruvi',
      'sticker_pack_hint': 'Mening stickerlarim',
      'saved': 'Saqlandi',
      'add_sticker': 'Sticker qo‘shish',
      'no_stickers_yet': 'Hali sticker yo‘q',
      'username_min_5': 'Kamida 5 ta belgi',
      'username_max_20': 'Ko‘pi bilan 20 ta belgi',
      'username_latin_only': 'Faqat lotin harflari ruxsat',
    },
    'ru': {
      'welcome': 'Добро пожаловать',
      'sign_in_subtitle': 'Войдите, чтобы продолжить',
      'email': 'Email',
      'password': 'Пароль',
      'sign_in': 'Войти',
      'sign_up': 'Регистрация',
      'continue_with': 'Продолжить',
      'google_sign_in': 'Войти через Google',
      'apple_sign_in': 'Войти через Apple',
      'error': 'Ошибка',
      'forgot_password': 'Забыли пароль?',
      'reset_password': 'Восстановить пароль',
      'send_reset': 'Отправить ссылку',
      'reset_sent': 'Ссылка для сброса отправлена на email',
      'required_email': 'Введите email',
      'invalid_email': 'Неверный email',
      'required_password': 'Введите пароль',
      'min_password': 'Минимум 8 символов',
      'confirm_password': 'Подтвердите пароль',
      'required_confirm_password': 'Подтвердите пароль',
      'password_mismatch': 'Пароли не совпадают',
      'or': 'или',
      'no_account_prompt': 'Нет аккаунта?',
      'have_account_prompt': 'Уже есть аккаунт?',
      'auth_footer': '© 2026 Chat App. Все права защищены.',
      'signup_title': 'Регистрация',
      'signup_subtitle': 'Пройдите бесплатную регистрацию',
      'username': 'Юзернейм',
      'first_name': 'Имя',
      'last_name': 'Фамилия',
      'birth_date': 'Дата рождения (ГГГГ-ММ-ДД)',
      'photo_url': 'URL фото профиля (опционально)',
      'bio': 'Био / О себе (опционально)',
      'profile_title': 'Профиль',
      'profile_subtitle': 'Обновите свои данные',
      'save_changes': 'Сохранить изменения',
      'delete_account': 'Удалить аккаунт',
      'delete_account_title': 'Удалить аккаунт?',
      'delete_account_body': 'Это действие безвозвратно удалит профиль.',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'sign_out': 'Выйти',
      'profile_updated': 'Профиль обновлен',
      'account_deleted': 'Аккаунт удален',
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
      'offline': 'Оффлайн',
      'last_seen': 'Был(а)',
      'input_hint': 'Напишите сообщение...',
      'no_messages': 'Пока нет сообщений',
      'settings_title': 'Настройки',
      'appearance': 'Оформление',
      'theme_system': 'Системная',
      'theme_light': 'Светлая',
      'theme_dark': 'Тёмная',
      'privacy_settings': 'Приватность',
      'read_receipts_title': 'Отчеты о прочтении',
      'read_receipts_subtitle': 'Показывать, когда вы прочитали сообщение',
      'secret_chat_default_title': 'Secret timer default',
      'secret_chat_default_subtitle':
          'Для новых сообщений по умолчанию использовать 30 секунд',
      'sticker_pack_title': 'Стикерпак',
      'sticker_pack_subtitle': 'Управление личным стикерпаком',
      'sticker_pack_hint': 'Мои стикеры',
      'saved': 'Сохранено',
      'add_sticker': 'Добавить стикер',
      'no_stickers_yet': 'Стикеров пока нет',
      'username_min_5': 'Минимум 5 символов',
      'username_max_20': 'Максимум 20 символов',
      'username_latin_only': 'Разрешены только латинские буквы',
    },
    'tg': {
      'welcome': 'Хуш омадед',
      'sign_in_subtitle': 'Барои идома ворид шавед',
      'email': 'Email',
      'password': 'Парол',
      'sign_in': 'Ворид шудан',
      'sign_up': 'Бақайдгирӣ',
      'continue_with': 'Идома додан',
      'google_sign_in': 'Вуруд тавассути Google',
      'apple_sign_in': 'Вуруд тавассути Apple',
      'error': 'Хато',
      'forgot_password': 'Паролро фаромӯш кардед?',
      'reset_password': 'Барқарор кардани парол',
      'send_reset': 'Ирсоли пайванди барқарорсозӣ',
      'reset_sent': 'Пайванд ба email фиристода шуд',
      'required_email': 'Email ворид кунед',
      'invalid_email': 'Email нодуруст',
      'required_password': 'Парол ворид кунед',
      'min_password': 'На камтар аз 8 аломат',
      'confirm_password': 'Тасдиқи парол',
      'required_confirm_password': 'Паролро тасдиқ кунед',
      'password_mismatch': 'Паролҳо мувофиқ нестанд',
      'or': 'ё',
      'no_account_prompt': 'Ҳисоб надоред?',
      'have_account_prompt': 'Ҳисоб доред?',
      'auth_footer': '© 2026 Chat App. Ҳама ҳуқуқҳо ҳифз шудаанд.',
      'signup_title': 'Бақайдгирӣ',
      'signup_subtitle': 'Ройгон бақайдгирӣ шавед',
      'username': 'Номи корбар',
      'first_name': 'Ном',
      'last_name': 'Насаб',
      'birth_date': 'Санаи таваллуд (YYYY-MM-DD)',
      'photo_url': 'URL акс (ихтиёрӣ)',
      'bio': 'Bio / Оиди худ (ихтиёрӣ)',
      'profile_title': 'Профил',
      'profile_subtitle': 'Маълумотро навсозӣ кунед',
      'save_changes': 'Захира кардан',
      'delete_account': 'Ҳисобро нест кардан',
      'delete_account_title': 'Ҳисоб нест шавад?',
      'delete_account_body': 'Ин амал профили шуморо пурра нест мекунад.',
      'cancel': 'Бекор кардан',
      'confirm': 'Тасдиқ',
      'sign_out': 'Баромадан',
      'profile_updated': 'Профил нав шуд',
      'account_deleted': 'Ҳисоб нест шуд',
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
      'offline': 'Офлайн',
      'last_seen': 'Охирин дидан',
      'input_hint': 'Паём нависед...',
      'no_messages': 'Ҳоло паём нест',
      'settings_title': 'Танзимот',
      'appearance': 'Намуд',
      'theme_system': 'Системавӣ',
      'theme_light': 'Равшан',
      'theme_dark': 'Торик',
      'privacy_settings': 'Махфият',
      'read_receipts_title': 'Тасдиқи хондан',
      'read_receipts_subtitle': 'Дигарон мебинанд, ки шумо паёмро кай хондаед',
      'secret_chat_default_title': 'Secret timer default',
      'secret_chat_default_subtitle':
          'Барои паёмҳои нав пешфарз 30 сония истифода шавад',
      'sticker_pack_title': 'Стикерпак',
      'sticker_pack_subtitle': 'Идоракунии стикерпак',
      'sticker_pack_hint': 'Стикерҳои ман',
      'saved': 'Сабт шуд',
      'add_sticker': 'Иловаи стикер',
      'no_stickers_yet': 'Ҳоло стикер нест',
      'username_min_5': 'Камаш 5 аломат',
      'username_max_20': 'Зиёда аз 20 аломат нашавад',
      'username_latin_only': 'Фақат ҳарфҳои лотинӣ иҷозат аст',
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
  String get continueWith => _t('continue_with');
  String get googleSignIn => _t('google_sign_in');
  String get appleSignIn => _t('apple_sign_in');
  String get error => _t('error');
  String get forgotPassword => _t('forgot_password');
  String get resetPassword => _t('reset_password');
  String get sendReset => _t('send_reset');
  String get resetSent => _t('reset_sent');
  String get requiredEmail => _t('required_email');
  String get invalidEmail => _t('invalid_email');
  String get requiredPassword => _t('required_password');
  String get minPassword => _t('min_password');
  String get confirmPassword => _t('confirm_password');
  String get requiredConfirmPassword => _t('required_confirm_password');
  String get passwordMismatch => _t('password_mismatch');
  String get or => _t('or');
  String get noAccountPrompt => _t('no_account_prompt');
  String get haveAccountPrompt => _t('have_account_prompt');
  String get authFooter => _t('auth_footer');
  String get signupTitle => _t('signup_title');
  String get signupSubtitle => _t('signup_subtitle');
  String get username => _t('username');
  String get firstName => _t('first_name');
  String get lastName => _t('last_name');
  String get birthDate => _t('birth_date');
  String get photoUrl => _t('photo_url');
  String get bio => _t('bio');
  String get profileTitle => _t('profile_title');
  String get profileSubtitle => _t('profile_subtitle');
  String get saveChanges => _t('save_changes');
  String get deleteAccount => _t('delete_account');
  String get deleteAccountTitle => _t('delete_account_title');
  String get deleteAccountBody => _t('delete_account_body');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get signOut => _t('sign_out');
  String get profileUpdated => _t('profile_updated');
  String get accountDeleted => _t('account_deleted');
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
  String get offline => _t('offline');
  String get lastSeen => _t('last_seen');
  String get inputHint => _t('input_hint');
  String get noMessages => _t('no_messages');
  String get settingsTitle => _t('settings_title');
  String get appearance => _t('appearance');
  String get themeSystem => _t('theme_system');
  String get themeLight => _t('theme_light');
  String get themeDark => _t('theme_dark');
  String get privacySettings => _t('privacy_settings');
  String get readReceiptsTitle => _t('read_receipts_title');
  String get readReceiptsSubtitle => _t('read_receipts_subtitle');
  String get secretChatDefaultTitle => _t('secret_chat_default_title');
  String get secretChatDefaultSubtitle => _t('secret_chat_default_subtitle');
  String get stickerPackTitle => _t('sticker_pack_title');
  String get stickerPackSubtitle => _t('sticker_pack_subtitle');
  String get stickerPackHint => _t('sticker_pack_hint');
  String get saved => _t('saved');
  String get addSticker => _t('add_sticker');
  String get noStickersYet => _t('no_stickers_yet');
  String get usernameMin5 => _t('username_min_5');
  String get usernameMax20 => _t('username_max_20');
  String get usernameLatinOnly => _t('username_latin_only');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((e) => e.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
