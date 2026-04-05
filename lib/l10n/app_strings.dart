import 'dart:io';
import 'translations.dart';

// ─── Language options ─────────────────────────────────────
const kLanguageOptions = [
  ('ru', 'Русский',   '🇷🇺'),
  ('en', 'English',   '🇬🇧'),
  ('es', 'Español',   '🇪🇸'),
  ('de', 'Deutsch',   '🇩🇪'),
  ('fr', 'Français',  '🇫🇷'),
  ('it', 'Italiano',  '🇮🇹'),
  ('pt', 'Português', '🇧🇷'),
  ('zh', '中文',       '🇨🇳'),
  ('ja', '日本語',     '🇯🇵'),
  ('hi', 'हिंदी',     '🇮🇳'),
];

/// Returns the system locale code mapped to one of our supported locales.
/// Falls back to 'ru' if not matched.
String systemLocale() {
  try {
    final raw = Platform.localeName; // e.g. "ru_RU", "en_US", "zh_CN"
    final code = raw.split('_').first.toLowerCase();
    if (kTranslations.containsKey(code)) return code;
  } catch (_) {}
  return 'ru';
}

// ─── String accessor ──────────────────────────────────────
/// Access translations via S.of(locale).key
class S {
  final String _locale;
  const S._(this._locale);

  factory S.of(String locale) => S._(
    kTranslations.containsKey(locale) ? locale : 'ru',
  );

  String _t(String key) =>
      kTranslations[_locale]?[key] ?? kTranslations['ru']?[key] ?? key;

  // Nav / tabs
  String get calendar   => _t('calendar');
  String get events     => _t('events');
  String get notes      => _t('notes');
  String get todos      => _t('todos');

  // Sections
  String get sectionEvents   => _t('sectionEvents');
  String get sectionNotes    => _t('sectionNotes');
  String get sectionTodos    => _t('sectionTodos');
  String get sectionToday    => _t('sectionToday');
  String get sectionUpcoming => _t('sectionUpcoming');
  String get sectionContent  => _t('sectionContent');
  String get sectionSort     => _t('sectionSort');
  String get sectionDisplay  => _t('sectionDisplay');

  // Actions
  String get save        => _t('save');
  String get cancel      => _t('cancel');
  String get delete      => _t('delete');
  String get done        => _t('done');
  String get add         => _t('add');
  String get edit        => _t('edit');
  String get move        => _t('move');
  String get select      => _t('select');
  String get choose      => _t('choose');
  String get search      => _t('search');
  String get collapseAll => _t('collapseAll');
  String get expandAll   => _t('expandAll');
  String get collapse    => _t('collapse');
  String get expand      => _t('expand');

  // Editors
  String get noteTitle       => _t('noteTitle');
  String get notePlaceholder => _t('notePlaceholder');
  String get eventTitle      => _t('eventTitle');
  String get eventBody       => _t('eventBody');
  String get todoTitle       => _t('todoTitle');
  String get taskPlaceholder => _t('taskPlaceholder');
  String get namePlaceholder => _t('namePlaceholder');
  String get reminder        => _t('reminder');
  String get repeat          => _t('repeat');
  String get repeatLabel     => _t('repeatLabel');
  String get color           => _t('color');
  String get noteColor       => _t('noteColor');
  String get cardColor       => _t('cardColor');
  String get folderColor     => _t('folderColor');
  String get dateTime        => _t('dateTime');

  // Delete dialogs
  String get deleteNote      => _t('deleteNote');
  String get deleteFolder    => _t('deleteFolder');
  String get deleteConfirm   => _t('deleteConfirm');
  String get deleteCannotUndo => _t('deleteCannotUndo');
  String get noTitle         => _t('noTitle');

  // Repeat options
  String get repeatNone    => _t('repeatNone');
  String get repeatDaily   => _t('repeatDaily');
  String get repeatWeekly  => _t('repeatWeekly');
  String get repeatMonthly => _t('repeatMonthly');
  String get repeatYearly  => _t('repeatYearly');
  String get repeatEvery   => _t('repeatEvery');
  String get repeatDays    => _t('repeatDays');
  String get repeatDaysHint => _t('repeatDaysHint');
  String repeatCustom(int days) => '${_t('repeatEvery')}$days${_t('repeatDays')}';

  // Reminder options
  String get remind5    => _t('remind5');
  String get remind10   => _t('remind10');
  String get remind15   => _t('remind15');
  String get remind30   => _t('remind30');
  String get remind60   => _t('remind60');
  String get remind1440 => _t('remind1440');
  String get remind2880 => _t('remind2880');
  String get remind10080 => _t('remind10080');
  String remindMinutes(int m) => kTranslations[_locale]?['remind$m']
      ?? kTranslations['ru']?['remind$m']
      ?? remind30;

  // Views
  String get viewList    => _t('viewList');
  String get viewGrid    => _t('viewGrid');
  String get viewCompact => _t('viewCompact');
  String get sortDate    => _t('sortDate');
  String get sortManual  => _t('sortManual');

  // Empty states
  String get noEvents   => _t('noEvents');
  String get noNotes    => _t('noNotes');
  String get noTodos    => _t('noTodos');
  String get noFolders  => _t('noFolders');
  String get noUpcoming => _t('noUpcoming');
  String get noResults  => _t('noResults');

  // Search hints
  String get searchNotes  => _t('searchNotes');
  String get searchEvents => _t('searchEvents');
  String get searchTodos  => _t('searchTodos');
  String get searchAll    => _t('searchAll');

  // Folders / sidebar
  String get folders       => _t('folders');
  String get newFolder     => _t('newFolder');
  String get manageFolders => _t('manageFolders');
  String get moveToFolder  => _t('moveToFolder');
  String get noFolder      => _t('noFolder');
  String get noCategory    => _t('noCategory');
  String get all           => _t('all');
  String get profile       => _t('profile');

  // Settings
  String get settings            => _t('settings');
  String get settingName         => _t('settingName');
  String get settingNameHint     => _t('settingNameHint');
  String get settingUiFont       => _t('settingUiFont');
  String get settingContentFont  => _t('settingContentFont');
  String get settingTheme        => _t('settingTheme');
  String get settingReminders    => _t('settingReminders');
  String get settingLanguage     => _t('settingLanguage');
  String get themeDark           => _t('themeDark');
  String get themeLight          => _t('themeLight');

  // Default names
  String get defaultTask  => _t('defaultTask');
  String get defaultList  => _t('defaultList');
  String get defaultNote  => _t('defaultNote');
  String get defaultEvent => _t('defaultEvent');

  // Calendar dates
  String get today     => _t('today');
  String get tomorrow  => _t('tomorrow');
  String get yesterday => _t('yesterday');

  // Weekdays short (Mon-Sun)
  List<String> get weekdaysShort =>
      [_t('mon'), _t('tue'), _t('wed'), _t('thu'), _t('fri'), _t('sat'), _t('sun')];

  // Weekdays 1-letter (year view)
  List<String> get weekdays1 =>
      [_t('mon1'), _t('tue1'), _t('wed1'), _t('thu1'), _t('fri1'), _t('sat1'), _t('sun1')];

  // Months lowercase (formatDate)
  List<String> get monthsLower =>
      [_t('jan'), _t('feb'), _t('mar'), _t('apr'), _t('may'), _t('jun'),
       _t('jul'), _t('aug'), _t('sep'), _t('oct'), _t('nov'), _t('dec')];

  // Months capitalized (calendar header)
  List<String> get monthsCapital =>
      [_t('janC'), _t('febC'), _t('marC'), _t('aprC'), _t('mayC'), _t('junC'),
       _t('julC'), _t('augC'), _t('sepC'), _t('octC'), _t('novC'), _t('decC')];

  // Bulk
  String get movedTo => _t('movedTo');
  String get deleteN => _t('deleteN');
  String movedToLabel(String label) => '${_t('movedTo')} «$label»';
  String deleteCount(int n) => '${_t('delete')} $n ${_t('deleteN')}';
}
