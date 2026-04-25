enum RuleMatchType {
  contains,
  startsWith,
  equals,
  regex;

  String get label => switch (this) {
        RuleMatchType.contains => 'Contiene',
        RuleMatchType.startsWith => 'Empieza con',
        RuleMatchType.equals => 'Coincide exacto',
        RuleMatchType.regex => 'Regex',
      };
}
