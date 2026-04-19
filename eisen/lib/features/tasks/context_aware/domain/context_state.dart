import 'package:flutter/material.dart';

enum ContextPermissionState { unknown, granted, denied }

@immutable
class ContextLocationPreset {
  const ContextLocationPreset({
    required this.tag,
    required this.latitude,
    required this.longitude,
    required this.labelEs,
    required this.labelEn,
    required this.subtitleEs,
    required this.subtitleEn,
  });

  final String tag;
  final double latitude;
  final double longitude;
  final String labelEs;
  final String labelEn;
  final String subtitleEs;
  final String subtitleEn;

  String labelFor(Locale locale) {
    return locale.languageCode == 'es' ? labelEs : labelEn;
  }

  String subtitleFor(Locale locale) {
    return locale.languageCode == 'es' ? subtitleEs : subtitleEn;
  }
}

const unknownContextPreset = ContextLocationPreset(
  tag: 'unknown',
  latitude: 0,
  longitude: 0,
  labelEs: 'Sin contexto',
  labelEn: 'No context',
  subtitleEs: 'Ubicación no disponible',
  subtitleEn: 'Location unavailable',
);

const homeContextPreset = ContextLocationPreset(
  tag: 'home',
  latitude: 19.4260,
  longitude: -99.1677,
  labelEs: 'Casa',
  labelEn: 'Home',
  subtitleEs: 'Rutinas personales y tareas del hogar',
  subtitleEn: 'Personal routines and home tasks',
);

const officeContextPreset = ContextLocationPreset(
  tag: 'office',
  latitude: 19.4328,
  longitude: -99.1332,
  labelEs: 'Oficina',
  labelEn: 'Office',
  subtitleEs: 'Trabajo profundo, reuniones y entregables',
  subtitleEn: 'Deep work, meetings and deliverables',
);

const errandsContextPreset = ContextLocationPreset(
  tag: 'errands',
  latitude: 19.4385,
  longitude: -99.1401,
  labelEs: 'Recados',
  labelEn: 'Errands',
  subtitleEs: 'Llamadas, compras y gestiones rápidas',
  subtitleEn: 'Calls, shopping and quick errands',
);

const contextLocationPresets = <ContextLocationPreset>[
  homeContextPreset,
  officeContextPreset,
  errandsContextPreset,
];

ContextLocationPreset contextPresetForTag(String? tag) {
  return contextLocationPresets.firstWhere(
    (preset) => preset.tag == tag,
    orElse: () => unknownContextPreset,
  );
}

String localizedContextTag(BuildContext context, String? tag) {
  final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
  return contextPresetForTag(tag).labelFor(locale);
}

@immutable
class ContextState {
  const ContextState({
    required this.currentLocationTag,
    required this.latitude,
    required this.longitude,
    required this.isAutoMode,
    required this.permissionState,
  });

  final String currentLocationTag;
  final double? latitude;
  final double? longitude;
  final bool isAutoMode;
  final ContextPermissionState permissionState;

  bool get hasCoordinates => latitude != null && longitude != null;

  ContextState copyWith({
    String? currentLocationTag,
    double? latitude,
    double? longitude,
    bool? isAutoMode,
    ContextPermissionState? permissionState,
  }) {
    return ContextState(
      currentLocationTag: currentLocationTag ?? this.currentLocationTag,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      permissionState: permissionState ?? this.permissionState,
    );
  }
}
