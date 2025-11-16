/// Task view mode for the Eisenhower matrix.
///
/// Controls how many tasks are emphasized in the current view.
/// Values map to top‑K presets plus a customizable option.
enum MatrixViewMode {
  top10,
  top25,
  top50,
  all,
  custom,
}

