/// Tonos de notificación disponibles en Eisen.
enum NotificationTone {
  /// Tono predeterminado del sistema.
  defaultTone,

  /// Campanada suave y sutil.
  chimeSoft,

  /// Campana corta.
  bellShort,

  /// Tick de madera minimalista.
  woodTick,

  /// Sin sonido (silencioso).
  mute,
}

extension NotificationToneX on NotificationTone {
  /// Nombre de visualización en español.
  String get labelEs {
    return switch (this) {
      NotificationTone.defaultTone => 'Predeterminado',
      NotificationTone.chimeSoft => 'Campanada suave',
      NotificationTone.bellShort => 'Campana corta',
      NotificationTone.woodTick => 'Tick de madera',
      NotificationTone.mute => 'Silencio',
    };
  }

  /// Nombre de visualización en inglés.
  String get labelEn {
    return switch (this) {
      NotificationTone.defaultTone => 'Default',
      NotificationTone.chimeSoft => 'Soft Chime',
      NotificationTone.bellShort => 'Short Bell',
      NotificationTone.woodTick => 'Wood Tick',
      NotificationTone.mute => 'Mute',
    };
  }

  /// Ruta del archivo de audio en assets.
  /// Retorna null para defaultTone (usa el del sistema) y mute (sin sonido).
  String? get assetPath {
    return switch (this) {
      NotificationTone.defaultTone => null,
      NotificationTone.chimeSoft => 'assets/sounds/chime_soft.mp3',
      NotificationTone.bellShort => 'assets/sounds/bell_short.mp3',
      NotificationTone.woodTick => 'assets/sounds/wood_tick.mp3',
      NotificationTone.mute => null,
    };
  }

  /// Identificador de serialización (para persistencia).
  String get id {
    return switch (this) {
      NotificationTone.defaultTone => 'default',
      NotificationTone.chimeSoft => 'chime_soft',
      NotificationTone.bellShort => 'bell_short',
      NotificationTone.woodTick => 'wood_tick',
      NotificationTone.mute => 'mute',
    };
  }

  /// Parse desde string de persistencia.
  static NotificationTone fromId(String id) {
    return switch (id) {
      'default' => NotificationTone.defaultTone,
      'chime_soft' => NotificationTone.chimeSoft,
      'bell_short' => NotificationTone.bellShort,
      'wood_tick' => NotificationTone.woodTick,
      'mute' => NotificationTone.mute,
      _ => NotificationTone.defaultTone,
    };
  }
}
