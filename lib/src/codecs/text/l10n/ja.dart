import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../frequency.dart';
import 'l10n.dart';

/// Japanese localization.
///
/// The encoder joins the parts of a rule in English order with spaces, so
/// restrictions that would precede the noun in Japanese are written in
/// parentheses after it, e.g. "毎日 月曜日と木曜日 （各月の1日または末日に限る）".
@immutable
class RruleL10nJa extends RruleL10n {
  const RruleL10nJa._();

  static Future<RruleL10nJa> create() async {
    await initializeDateFormatting('ja');
    return const RruleL10nJa._();
  }

  @override
  String get locale => 'ja';

  @override
  String frequencyInterval(Frequency frequency, int interval) {
    String plurals({
      required String one,
      required String two,
      required String unit,
    }) {
      return switch (interval) {
        1 => one,
        2 => two,
        _ => '$interval$unitごと',
      };
    }

    return {
      Frequency.secondly: plurals(one: '毎秒', two: '2秒ごと', unit: '秒'),
      Frequency.minutely: plurals(one: '毎分', two: '2分ごと', unit: '分'),
      Frequency.hourly: plurals(one: '毎時', two: '2時間ごと', unit: '時間'),
      Frequency.daily: plurals(one: '毎日', two: '隔日', unit: '日'),
      Frequency.weekly: plurals(one: '毎週', two: '隔週', unit: '週間'),
      Frequency.monthly: plurals(one: '毎月', two: '隔月', unit: 'か月'),
      Frequency.yearly: plurals(one: '毎年', two: '隔年', unit: '年'),
    }[frequency]!;
  }

  @override
  String until(DateTime until, Frequency frequency) {
    final untilString = formatWithIntl(
      () => DateFormat('y年M月d日(E) H:mm', 'ja').format(until),
    );
    return '、$untilStringまで';
  }

  @override
  String count(int count) => '、$count回';

  @override
  String range(String start, String end) => '$start～$end';

  @override
  String onInstances(String instances) {
    return instances
        .replaceAllMapped(
          RegExp(r'最後から(\d+)番目'),
          (match) => '最後から${match[1]}回目',
        )
        .replaceAllMapped(RegExp(r'第(\d+)'), (match) => '${match[1]}回目')
        .replaceAll('最終', '最後');
  }

  @override
  String inMonths(String months, {InOnVariant variant = InOnVariant.simple}) =>
      _inVariant(months, variant);

  @override
  String inWeeks(String weeks, {InOnVariant variant = InOnVariant.simple}) {
    final string = weeks
        .replaceAllMapped(
          RegExp(r'最後から(\d+)番目'),
          (match) => '最後から${match[1]}番目の週',
        )
        .replaceAllMapped(RegExp(r'第(\d+)'), (match) => '第${match[1]}週')
        .replaceAll('最終', '最終週');
    return _inVariant(string, variant);
  }

  String _inVariant(String string, InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => '$stringに',
      InOnVariant.also => '（$stringに限る）',
      InOnVariant.instanceOf => '（$stringのうち）',
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
        frequency == DaysOfWeekFrequency.monthly ? 'その月の' : 'その年の';
    final prefix = indicateFrequency ? frequencyString : '';
    return _onVariant('$prefix$days', variant);
  }

  @override
  String? get weekdaysString => '平日';
  @override
  String get everyXDaysOfWeekPrefix => '';
  @override
  String nthDaysOfWeek(Iterable<int> occurrences, String daysOfWeek) {
    if (occurrences.isEmpty) return daysOfWeek;

    // "第1・第3月曜日", "最後から2番目の木曜日"
    final ordinals = occurrences.map(ordinal).join('・');
    final separator = ordinals.endsWith('番目') ? 'の' : '';
    return '$ordinals$separator$daysOfWeek';
  }

  @override
  String onDaysOfMonth(
    String days, {
    DaysOfVariant daysOfVariant = DaysOfVariant.dayAndFrequency,
    InOnVariant variant = InOnVariant.simple,
  }) {
    final string = days
        .replaceAllMapped(
          RegExp(r'最後から(\d+)番目'),
          (match) => '最後から${match[1]}番目の日',
        )
        .replaceAllMapped(RegExp(r'第(\d+)'), (match) => '${match[1]}日')
        .replaceAll('最終', '末日');
    final prefix = daysOfVariant == DaysOfVariant.dayAndFrequency ? '各月の' : '';
    return _onVariant('$prefix$string', variant);
  }

  @override
  String onDaysOfYear(
    String days, {
    InOnVariant variant = InOnVariant.simple,
  }) {
    final string = days
        .replaceAllMapped(
          RegExp(r'最後から(\d+)番目'),
          (match) => '最後から${match[1]}番目の日',
        )
        .replaceAllMapped(RegExp(r'第(\d+)'), (match) => '${match[1]}日目')
        .replaceAll('最終', '最終日');
    return _onVariant('1年の$string', variant);
  }

  String _onVariant(String string, InOnVariant variant) {
    return switch (variant) {
      InOnVariant.simple => string,
      InOnVariant.also => '（$stringに限る）',
      InOnVariant.instanceOf => '（$stringのうち）',
    };
  }

  @override
  String list(List<String> items, ListCombination combination) {
    // Restrictions in parentheses simply follow each other.
    if (items.every((it) => it.startsWith('（'))) return items.join();

    return switch (combination) {
      ListCombination.conjunctiveShort =>
        items.length == 2 ? items.join('と') : items.join('・'),
      ListCombination.conjunctiveLong => items.join('、'),
      ListCombination.disjunctive => RruleL10n.defaultList(
          items,
          two: 'または',
          start: '、',
          middle: '、',
          end: '、または',
        ),
    };
  }

  @override
  String ordinal(int number) {
    assert(number != 0);

    return switch (number) {
      -1 => '最終',
      < 0 => '最後から${-number}番目',
      _ => '第$number',
    };
  }
}
