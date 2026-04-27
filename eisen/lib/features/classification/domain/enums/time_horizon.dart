enum TimeHorizon {
  today,
  thisWeek,
  thisMonth,
  someday;

  String get label => switch (this) {
        TimeHorizon.today => 'Hoy',
        TimeHorizon.thisWeek => 'Esta semana',
        TimeHorizon.thisMonth => 'Este mes',
        TimeHorizon.someday => 'Algún día',
      };
}
