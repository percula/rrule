import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../frequency.dart';
import 'l10n.dart';

@immutable
class RruleL10nEs extends RruleL10n {
  const RruleL10nEs._();

  static Future<RruleL10nEs> create() async {
    await initializeDateFormatting('es');
    return const RruleL10nEs._();
  }

  @override
  String get locale => 'es';

  @override
  String frequencyInterval(Frequency frequency, int interval) {
    String plurals({
      required String one,
      required String plural,
    }) {
      return switch (interval) {
        1 => one,
        2 => 'Cada dos $plural',
        _ => 'Cada $interval $plural',
      };
    }

    return {
      Frequency.secondly: plurals(one: 'Cada segundo', plural: 'segundos'),
      Frequency.minutely: plurals(one: 'Cada minuto', plural: 'minutos'),
      Frequency.hourly: plurals(one: 'Cada hora', plural: 'horas'),
      Frequency.daily: plurals(one: 'Todos los días', plural: 'días'),
      Frequency.weekly: plurals(one: 'Todas las semanas', plural: 'semanas'),
      Frequency.monthly: plurals(one: 'Todos los meses', plural: 'meses'),
      Frequency.yearly: plurals(one: 'Todos los años', plural: 'años'),
    }[frequency]!;
  }

  @override
  String until(DateTime until, Frequency frequency) {
    final at = until.hour == 1 ? "'a la'" : "'a las'";
    final untilString = formatWithIntl(
      () => DateFormat("EEEE d 'de' MMMM 'de' y $at H:mm", 'es').format(until),
    );
    return ', hasta el $untilString';
  }

  @override
  String count(int count) => count == 1 ? ', una vez' : ', $count veces';

  @override
  String range(String start, String end) {
    final from = switch (start) {
      _ when start.startsWith('el ') =>
        'del ${_unshortened(start.substring(3))}',
      _ when start.startsWith('los ') => 'de ${_singular(start.substring(4))}',
      _ => 'de $start',
    };
    final to = switch (end) {
      _ when end.startsWith('el ') => 'al ${end.substring(3)}',
      _ when end.startsWith('los ') => 'a ${_singular(end.substring(4))}',
      _ => 'a $end',
    };
    return '$from $to';
  }

  @override
  String onInstances(String instances) => '${_feminine(instances)} ocurrencia';

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) {
    // "de enero a marzo, agosto y septiembre" already works on its own.
    final inMonths = months.startsWith('de ') ? months : 'en $months';
    return switch (variant) {
      InOnVariant.simple => inMonths,
      InOnVariant.also => 'que caen $inMonths',
      InOnVariant.instanceOf =>
        months.startsWith('de ') ? months : 'de $months',
    };
  }

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) {
    final string = '${_feminine(weeks)} semana del año';
    // "de la primera a la cuarta semana" already works on its own.
    final during = string.startsWith('de ') ? string : 'en $string';
    return switch (variant) {
      InOnVariant.simple => during,
      InOnVariant.also => 'que caen $during',
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
        frequency == DaysOfWeekFrequency.monthly ? 'del mes' : 'del año';
    final suffix = indicateFrequency ? ' $frequencyString' : '';
    final string = '$days$suffix';
    if (variant != InOnVariant.instanceOf) return string;

    // "la última ocurrencia de los días entre semana" instead of "… de de
    // lunes a viernes".
    final weekdays = weekdaysString!;
    return _of(
      string.startsWith(weekdays)
          ? 'los días entre semana${string.substring(weekdays.length)}'
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
    // "el primer jueves y viernes" instead of "el primer los jueves y los
    // viernes", and "el segundo jueves, viernes y sábado" instead of a range.
    final days = daysOfWeek
        .replaceAllMapped(
          RegExp(r'de (\S+) a (\S+)'),
          (match) => _expandWeekdayRange(match[1]!, match[2]!),
        )
        .replaceAllMapped(
          RegExp(r'\blos (\S+)'),
          (match) => _singular(match[1]!),
        );
    return '$ordinals $days';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    // Dates use cardinal numbers: "el día 1 y el último día", "del 2 al 5".
    final dates = _asDates(days);
    final endsWithDate = RegExp(r'\d$').hasMatch(dates);
    final string = switch (daysOfVariant) {
      DaysOfVariant.simple => dates,
      DaysOfVariant.day => endsWithDate ? dates : '$dates día',
      DaysOfVariant.dayAndFrequency =>
        endsWithDate ? '$dates del mes' : '$dates día del mes',
    };
    return _onVariant(string, variant);
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) =>
      _onVariant('$days día del año', variant);

  String _onVariant(String string, InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => string,
      InOnVariant.also => 'que caen $string',
      InOnVariant.instanceOf => _of(string),
    };
  }

  @override
  String list(List<String> items, ListCombination combination) {
    final mapped = [
      for (final item in items)
        _weekdays.contains(item) ? 'los ${_plural(item)}' : item,
    ];
    final isDisjunctive = combination == ListCombination.disjunctive;
    if (mapped.length == 1) return mapped.single;

    // "y" becomes "e" before an /i/ sound, "o" becomes "u" before an /o/ sound.
    final last = mapped.last;
    final conjunction = isDisjunctive
        ? (RegExp('^h?[oó]').hasMatch(last) ? 'u' : 'o')
        : (RegExp('^h?[ií](?![aeoó])').hasMatch(last) ? 'e' : 'y');
    final rest = mapped.sublist(0, mapped.length - 1).join(', ');
    return '$rest $conjunction $last';
  }

  @override
  String ordinal(int number) {
    assert(number != 0);

    if (number < 0) {
      return switch (number) {
        -1 => 'el último',
        -2 => 'el penúltimo',
        -3 => 'el antepenúltimo',
        _ => 'el ${_unshortened(_ordinalWord(-number - 1))} antes del último',
      };
    }
    return 'el ${_ordinalWord(number)}';
  }

  static const _ordinalWords = [
    'primer',
    'segundo',
    'tercer',
    'cuarto',
    'quinto',
    'sexto',
    'séptimo',
    'octavo',
    'noveno',
    'décimo',
  ];

  static String _ordinalWord(int number) =>
      number <= _ordinalWords.length ? _ordinalWords[number - 1] : '$number.º';

  /// "primer" and "tercer" are only shortened directly before a noun.
  static String _unshortened(String ordinal) {
    return switch (ordinal) {
      'primer' => 'primero',
      'tercer' => 'tercero',
      _ => ordinal,
    };
  }

  /// Turns "el primer y el último" into "el día 1 y el último".
  static String _asDates(String days) {
    return days.replaceAllMapped(
      RegExp(r'\b(el|del|al) ([^\s,]+)'),
      (match) {
        final number = _dayNumber(match[2]!);
        // Keep "el tercero antes del último" as it is.
        final isRelative = days.startsWith(' antes', match.end);
        if (number == null || isRelative) return match[0]!;
        return match[1] == 'el' ? 'el día $number' : '${match[1]} $number';
      },
    );
  }

  static int? _dayNumber(String ordinal) {
    final index = _ordinalWords.indexOf(ordinal);
    if (index >= 0) return index + 1;
    if (ordinal == 'primero') return 1;
    if (ordinal == 'tercero') return 3;
    final match = RegExp(r'^(\d+)\.º$').firstMatch(ordinal);
    return match == null ? null : int.parse(match[1]!);
  }

  Set<String> get _weekdays => {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          dayOfWeek(day),
      };

  /// Turns "el primer y el último día" into "del primer y el último día".
  static String _of(String string) {
    return switch (string) {
      _ when string.startsWith('el ') => 'del ${string.substring(3)}',
      _ when string.startsWith('de ') => string,
      _ => 'de $string',
    };
  }

  /// "lunes" stays "lunes", "sábado" becomes "sábados".
  static String _plural(String day) => day.endsWith('s') ? day : '${day}s';
  static String _singular(String day) =>
      day.endsWith('os') ? day.substring(0, day.length - 1) : day;

  /// Adapts ordinals to a feminine noun ("la primera y la última semana").
  static String _feminine(String string) {
    return string
        .replaceAll(RegExp(r'\bel '), 'la ')
        .replaceAll(RegExp(r'\bdel '), 'de la ')
        .replaceAll(RegExp(r'\bal '), 'a la ')
        .replaceAllMapped(
          RegExp(r'\b(primer|tercer)o?\b'),
          (match) => '${match[1]}a',
        )
        .replaceAllMapped(
          RegExp(
            '(^| )(segund|cuart|quint|sext|séptim|octav|noven|décim|últim'
            r'|penúltim|antepenúltim)o(?= |$)',
          ),
          (match) => '${match[1]}${match[2]}a',
        )
        .replaceAll('.º', '.ª');
  }

  String _expandWeekdayRange(String start, String end) {
    final weekdays = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        dayOfWeek(day),
    ];
    final startIndex = weekdays.indexOf(start);
    final endIndex = weekdays.indexOf(end);
    if (startIndex < 0 || endIndex < 0) return 'de $start a $end';

    final days = [
      for (var i = startIndex; i != endIndex; i = (i + 1) % weekdays.length)
        weekdays[i],
      end,
    ];
    return '${days.sublist(0, days.length - 1).join(', ')} y ${days.last}';
  }
}
