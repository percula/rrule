import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../frequency.dart';
import 'l10n.dart';

@immutable
class RruleL10nDe extends RruleL10n {
  const RruleL10nDe._();

  static Future<RruleL10nDe> create() async {
    // TODO(JonasWanke): Move `initializeDateFormatting(…)` call to the
    // library's user
    await initializeDateFormatting('de');
    return const RruleL10nDe._();
  }

  @override
  String get locale => 'de_DE';

  @override
  String frequencyInterval(Frequency frequency, int interval) {
    String plurals({
      required String one,
      required String everyOther,
      required String plural,
    }) {
      return switch (interval) {
        1 => one,
        2 => everyOther,
        _ => 'Alle $interval $plural',
      };
    }

    return {
      Frequency.secondly: plurals(
        one: 'Sekündlich',
        everyOther: 'Jede zweite Sekunde',
        plural: 'Sekunden',
      ),
      Frequency.minutely: plurals(
        one: 'Minütlich',
        everyOther: 'Jede zweite Minute',
        plural: 'Minuten',
      ),
      Frequency.hourly: plurals(
        one: 'Stündlich',
        everyOther: 'Jede zweite Stunde',
        plural: 'Stunden',
      ),
      Frequency.daily: plurals(
        one: 'Täglich',
        everyOther: 'Jeden zweiten Tag',
        plural: 'Tage',
      ),
      Frequency.weekly: plurals(
        one: 'Wöchentlich',
        everyOther: 'Jede zweite Woche',
        plural: 'Wochen',
      ),
      Frequency.monthly: plurals(
        one: 'Monatlich',
        everyOther: 'Jeden zweiten Monat',
        plural: 'Monate',
      ),
      Frequency.yearly: plurals(
        one: 'Jährlich',
        everyOther: 'Jedes zweite Jahr',
        plural: 'Jahre',
      ),
    }[frequency]!;
  }

  @override
  String until(DateTime until, Frequency frequency) {
    final untilString = formatWithIntl(
      () => DateFormat("EEEE, d. MMMM y 'um' H:mm 'Uhr'", 'de').format(until),
    );
    return ', bis $untilString';
  }

  @override
  String count(int count) {
    return switch (count) {
      1 => ', einmal',
      2 => ', zweimal',
      _ => ', $count-mal',
    };
  }

  @override
  String range(String start, String end) {
    if (_weekdays.contains(start) && _weekdays.contains(end)) {
      return '${_adverb(start)} bis ${_adverb(end)}';
    }
    if (_months.contains(start)) return 'von $start bis $end';
    return 'vom $start bis zum $end';
  }

  @override
  String onInstances(String instances) =>
      'jeweils das ${_nominativeNeuter(instances)} Vorkommen';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) {
    // "von Januar bis März, August und September" works on its own.
    final string = months.startsWith('von ') ? months : 'im $months';
    return variant == InOnVariant.also ? 'nur $string' : string;
  }

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) {
    final feminine =
        weeks.replaceAll('vom ', 'von der ').replaceAll('bis zum ', 'bis zur ');
    final string = '$feminine Woche des Jahres';
    return switch (variant) {
      InOnVariant.simple => _in(string),
      InOnVariant.also => 'nur ${_in(string)}',
      InOnVariant.instanceOf =>
        feminine.startsWith('von ') ? string : 'der $string',
    };
  }

  static String _in(String string) =>
      string.startsWith('von ') ? string : 'in der $string';

  @override
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  }) {
    assert(variant != InOnVariant.also);

    final frequencyString =
        frequency == DaysOfWeekFrequency.monthly ? 'Monats' : 'Jahres';
    final suffix = indicateFrequency ? ' des $frequencyString' : '';
    final string = '$days$suffix';
    if (variant != InOnVariant.instanceOf) return string;

    // "von Montag und dem letzten Donnerstag" instead of "von montags und am
    // letzten Donnerstag".
    final nouns = _adverbsToNouns(string).replaceAllMapped(
      RegExp('(^|, | und )am '),
      (match) => '${match[1]}dem ',
    );
    return 'von $nouns';
  }

  @override
  String? get weekdaysString =>
      range(dayOfWeek(DateTime.monday), dayOfWeek(DateTime.friday));
  @override
  String get everyXDaysOfWeekPrefix => '';
  @override
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek) {
    if (occurrences.isEmpty) return daysOfWeek;

    final ordinals = list(
      occurrences.map(ordinal).toList(),
      ListCombination.conjunctiveShort,
    );
    // "am ersten Donnerstag und Freitag" instead of "am ersten donnerstags und
    // freitags", and "am zweiten Donnerstag, Freitag und Samstag" instead of a
    // range.
    final days = _adverbsToNouns(
      daysOfWeek.replaceAllMapped(
        RegExp(r'(\p{Ll}+)s bis (\p{Ll}+)s', unicode: true),
        (match) => _expandWeekdayRange(
          _capitalized(match[1]!),
          _capitalized(match[2]!),
        ),
      ),
    );
    return 'am $ordinals $days';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    final string = switch (daysOfVariant) {
      // Dates use numbers: "am 1. und 15.".
      DaysOfVariant.simple => days.replaceAllMapped(
          RegExp(r'\b\p{L}+en\b', unicode: true),
          (match) {
            final number = _ordinalNumber(match[0]!);
            return number == null ? match[0]! : '$number.';
          },
        ),
      DaysOfVariant.day => '$days Tag',
      DaysOfVariant.dayAndFrequency => '$days Tag des Monats',
    };
    return _onVariant(string, variant);
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) =>
      _onVariant('$days Tag des Jahres', variant);

  String _onVariant(String string, InOnVariant variant) {
    // "vom ersten bis zum fünften, am 26. oder vom drittletzten bis zum
    // letzten Tag" doesn't need another "am" in front.
    final isRange = string.startsWith('vom ');
    if (isRange) {
      string = string.replaceAllMapped(
        RegExp('(, | und | oder )(?!vom )'),
        (match) => '${match[1]}am ',
      );
    }
    return switch (variant) {
      InOnVariant.simple => isRange ? string : 'am $string',
      InOnVariant.also => isRange ? 'nur $string' : 'nur am $string',
      InOnVariant.instanceOf => isRange ? string : 'vom $string',
    };
  }

  @override
  String list(List<String> items, ListCombination combination) {
    final two = combination == ListCombination.disjunctive ? ' oder ' : ' und ';
    return RruleL10n.defaultList(
      [
        for (final item in items)
          _weekdays.contains(item) ? _adverb(item) : item,
      ],
      two: two,
      end: two,
    );
  }

  @override
  String ordinal(int number) {
    assert(number != 0);

    const counting = [
      'erst',
      'zweit',
      'dritt',
      'viert',
      'fünft',
      'sechst',
      'siebt',
      'acht',
      'neunt',
      'zehnt',
    ];
    final n = number.abs();
    return switch (number) {
      -1 => 'letzten',
      -2 => 'vorletzten',
      _ when n > counting.length => number < 0 ? '$n.-letzten' : '$n.',
      < 0 => '${counting[n - 1]}letzten',
      _ => '${counting[n - 1]}en',
    };
  }

  int? _ordinalNumber(String ordinal) {
    for (var number = 1; number <= 10; number++) {
      if (this.ordinal(number) == ordinal) return number;
    }
    return null;
  }

  Set<String> get _weekdays => {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          dayOfWeek(day),
      };

  Set<String> get _months => {for (var m = 1; m <= 12; m++) month(m)};

  /// "Montag" becomes "montags".
  static String _adverb(String day) => '${day.toLowerCase()}s';

  static String _capitalized(String string) =>
      '${string[0].toUpperCase()}${string.substring(1)}';

  /// "montags" becomes "Montag".
  String _adverbsToNouns(String string) {
    return string.replaceAllMapped(
      RegExp(r'(\p{Ll}+)s(?!\p{L})', unicode: true),
      (match) {
        final noun = _capitalized(match[1]!);
        return _weekdays.contains(noun) ? noun : match[0]!;
      },
    );
  }

  /// "ersten und vorletzten" becomes "erste und vorletzte" (as in "das erste
  /// und vorletzte Vorkommen").
  static String _nominativeNeuter(String string) =>
      string.replaceAll(RegExp('(?<=[a-zäöü])en(?![a-zäöü])'), 'e');

  String _expandWeekdayRange(String start, String end) {
    final weekdays = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        dayOfWeek(day),
    ];
    final startIndex = weekdays.indexOf(start);
    final endIndex = weekdays.indexOf(end);
    if (startIndex < 0 || endIndex < 0) {
      return '${_adverb(start)} bis ${_adverb(end)}';
    }

    final days = [
      for (var i = startIndex; i != endIndex; i = (i + 1) % weekdays.length)
        weekdays[i],
      end,
    ];
    return RruleL10n.defaultList(days, two: ' und ', end: ' und ');
  }
}
