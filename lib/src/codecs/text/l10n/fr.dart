import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../frequency.dart';
import 'l10n.dart';

@immutable
class RruleL10nFr extends RruleL10n {
  const RruleL10nFr._();

  static Future<RruleL10nFr> create() async {
    await initializeDateFormatting('fr');
    return const RruleL10nFr._();
  }

  @override
  String get locale => 'fr';

  @override
  String frequencyInterval(Frequency frequency, int interval) {
    String plurals(String plural, {bool isFeminine = false}) {
      final every = isFeminine ? 'Toutes les' : 'Tous les';
      return switch (interval) {
        1 => '$every $plural',
        2 => '$every deux $plural',
        _ => '$every $interval $plural',
      };
    }

    return {
      Frequency.secondly: plurals('secondes', isFeminine: true),
      Frequency.minutely: plurals('minutes', isFeminine: true),
      Frequency.hourly: plurals('heures', isFeminine: true),
      Frequency.daily: plurals('jours'),
      Frequency.weekly: plurals('semaines', isFeminine: true),
      Frequency.monthly: plurals('mois'),
      Frequency.yearly: plurals('ans'),
    }[frequency]!;
  }

  @override
  String until(DateTime until, Frequency frequency) {
    final day = until.day == 1 ? '1er' : '${until.day}';
    final untilString = formatWithIntl(
      () => DateFormat("EEEE '$day' MMMM y 'à' H 'h' mm", 'fr').format(until),
    );
    return ", jusqu'au $untilString";
  }

  @override
  String count(int count) => count == 1 ? ', une fois' : ', $count fois';

  @override
  String range(String start, String end) {
    final from = switch (start) {
      _ when start.startsWith('le ') => 'du ${start.substring(3)}',
      _ when _weekdays.contains(start) => 'du $start',
      _ => _withDe(start),
    };
    final to = switch (end) {
      _ when end.startsWith('le ') => 'au ${end.substring(3)}',
      _ when end.startsWith("l'") => 'à $end',
      _ when _weekdays.contains(end) => 'au $end',
      _ => 'à $end',
    };
    return '$from $to';
  }

  @override
  String onInstances(String instances) => '${_feminine(instances)} occurrence';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) {
    return switch (variant) {
      InOnVariant.simple => _prefixMonths(months, 'en '),
      InOnVariant.also => 'qui tombent ${_prefixMonths(months, 'en ')}',
      InOnVariant.instanceOf => _prefixMonths(months, 'de '),
    };
  }

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) {
    final string = "${_feminine(weeks)} semaine de l'année";
    // "de la 1re à la 4e semaine" already works on its own.
    final during = string.startsWith('de ') ? string : 'pendant $string';
    return switch (variant) {
      InOnVariant.simple => during,
      InOnVariant.also => 'qui tombent $during',
      InOnVariant.instanceOf => _of(string),
    };
  }

  @override
  String onDaysOfWeek(
    String days, {
    bool indicateFrequency = false,
    DaysOfWeekFrequency? frequency = DaysOfWeekFrequency.monthly,
    InOnVariant variant = InOnVariant.simple,
  }) {
    assert(variant != InOnVariant.also);

    final frequencyString =
        frequency == DaysOfWeekFrequency.monthly ? 'du mois' : "de l'année";
    final suffix = indicateFrequency ? ' $frequencyString' : '';
    final string = '$days$suffix';
    if (variant != InOnVariant.instanceOf) return string;

    // "la dernière occurrence des jours de semaine" instead of "… du lundi au
    // vendredi", which would read like a range.
    final weekdays = weekdaysString!;
    return _of(
      string.startsWith(weekdays)
          ? 'les jours de semaine${string.substring(weekdays.length)}'
          : string,
    );
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
    // "le 1er jeudi et vendredi" instead of "le 1er le jeudi et le vendredi",
    // and "le 2e jeudi, vendredi et samedi" instead of a range.
    final days = daysOfWeek
        .replaceAllMapped(
          RegExp(r'du (\S+) au (\S+)'),
          (match) => _expandWeekdayRange(match[1]!, match[2]!),
        )
        .replaceAll(RegExp(r'\ble '), '');
    return '$ordinals $days';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    final string = switch (daysOfVariant) {
      // Dates use cardinal numbers, except for the first: "le 1er et le 15".
      DaysOfVariant.simple =>
        days.replaceAllMapped(RegExp(r'\b(\d+)e\b'), (match) => match[1]!),
      DaysOfVariant.day => '$days jour',
      DaysOfVariant.dayAndFrequency => '$days jour du mois',
    };
    return _onVariant(string, variant);
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) =>
      _onVariant("$days jour de l'année", variant);

  String _onVariant(String string, InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => string,
      InOnVariant.also => 'qui tombent $string',
      InOnVariant.instanceOf => _of(string),
    };
  }

  @override
  String list(List<String> items, ListCombination combination) {
    final two = combination == ListCombination.disjunctive ? ' ou ' : ' et ';
    return RruleL10n.defaultList(
      [
        for (final item in items) _weekdays.contains(item) ? 'le $item' : item,
      ],
      two: two,
      end: two,
    );
  }

  @override
  String ordinal(int number) {
    assert(number != 0);

    return switch (number) {
      1 => 'le 1er',
      -1 => 'le dernier',
      -2 => "l'avant-dernier",
      -3 => "l'antépénultième",
      < 0 => 'le ${-number - 1}e avant le dernier',
      _ => 'le ${number}e',
    };
  }

  Set<String> get _weekdays => {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          dayOfWeek(day),
      };

  Set<String> get _months => {for (var m = 1; m <= 12; m++) month(m)};

  static final _itemStart = RegExp('(^|, | et | ou )');

  /// Adds [prefix] (e.g., "en " or "de ") to every single month in [months],
  /// leaving ranges like "de janvier à mars" untouched.
  String _prefixMonths(String months, String prefix) {
    final pattern = RegExp(
      '${_itemStart.pattern}(${_months.join('|')})(?=\$|, | et | ou )',
    );
    return months.replaceAllMapped(pattern, (match) {
      final month = match[2]!;
      return '${match[1]}${prefix == 'de ' ? _withDe(month) : '$prefix$month'}';
    });
  }

  /// Turns "le 1er et le dernier jour" into "du 1er et du dernier jour".
  String _of(String string) {
    return string.replaceAllMapped(
      RegExp("${_itemStart.pattern}(le |la |l'|les )"),
      (match) {
        final article = switch (match[2]!) {
          'le ' => 'du ',
          'les ' => 'des ',
          final other => 'de $other',
        };
        return '${match[1]}$article';
      },
    );
  }

  static String _withDe(String string) =>
      RegExp('^[aeiouyàâéèêîôû]').hasMatch(string) ? "d'$string" : 'de $string';

  /// Adapts ordinals to a feminine noun ("la 1re et la dernière semaine").
  static String _feminine(String string) {
    return string
        .replaceAll(RegExp(r'\ble '), 'la ')
        .replaceAll(RegExp(r'\bdu '), 'de la ')
        .replaceAll(RegExp(r'\bau '), 'à la ')
        .replaceAll('1er', '1re')
        .replaceAll('dernier', 'dernière');
  }

  String _expandWeekdayRange(String start, String end) {
    final weekdays = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        dayOfWeek(day),
    ];
    final startIndex = weekdays.indexOf(start);
    final endIndex = weekdays.indexOf(end);
    if (startIndex < 0 || endIndex < 0) return 'du $start au $end';

    final days = [
      for (var i = startIndex; i != endIndex; i = (i + 1) % weekdays.length)
        weekdays[i],
      end,
    ];
    return RruleL10n.defaultList(days, two: ' et ', end: ' et ');
  }
}
