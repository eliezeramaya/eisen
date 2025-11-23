import 'package:audioplayers/audioplayers.dart';
import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio para manejar preview y configuración de tonos de notificación.
class NotificationSoundService {
  NotificationSoundService();

  final AudioPlayer _player = AudioPlayer();

  /// Reproduce un preview del tono seleccionado.
  ///
  /// Para defaultTone y mute, no reproduce nada.
  /// Para tonos custom, reproduce el asset correspondiente.
  Future<void> playPreview(NotificationTone tone) async {
    final assetPath = tone.assetPath;
    if (assetPath == null) {
      // defaultTone o mute - no hay preview
      return;
    }

    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      // Silently fail in preview
      // En producción, podrías loggear esto
    }
  }

  /// Detiene el preview actual.
  Future<void> stopPreview() async {
    try {
      await _player.stop();
    } catch (e) {
      // Ignore
    }
  }

  /// Construye NotificationDetails con el tono especificado para Android.
  ///
  /// Para iOS, usa el sonido predeterminado del sistema.
  NotificationDetails buildDetailsForTone(NotificationTone tone) {
    const iOS = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final android = _buildAndroidDetails(tone);

    return NotificationDetails(
      android: android,
      iOS: iOS,
    );
  }

  AndroidNotificationDetails _buildAndroidDetails(NotificationTone tone) {
    // Si es mute, sin sonido
    if (tone == NotificationTone.mute) {
      return const AndroidNotificationDetails(
        'eisen_default_channel',
        'Notificaciones de Eisen',
        channelDescription: 'Recordatorios y alertas de productividad',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        enableVibration: false,
      );
    }

    // Si es defaultTone, usa el sonido predeterminado
    if (tone == NotificationTone.defaultTone) {
      return const AndroidNotificationDetails(
        'eisen_default_channel',
        'Notificaciones de Eisen',
        channelDescription: 'Recordatorios y alertas de productividad',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
    }

    // Para tonos personalizados, especifica el raw resource
    // Nota: Los archivos deben estar en android/app/src/main/res/raw/
    final soundFileName = _getRawResourceName(tone);

    return AndroidNotificationDetails(
      'eisen_default_channel',
      'Notificaciones de Eisen',
      channelDescription: 'Recordatorios y alertas de productividad',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundFileName),
      playSound: true,
      enableVibration: true,
    );
  }

  /// Obtiene el nombre del archivo raw resource (sin extensión).
  String _getRawResourceName(NotificationTone tone) {
    return switch (tone) {
      NotificationTone.chimeSoft => 'chime_soft',
      NotificationTone.bellShort => 'bell_short',
      NotificationTone.woodTick => 'wood_tick',
      NotificationTone.defaultTone => 'default',
      NotificationTone.mute => '',
    };
  }

  /// Libera recursos del player.
  void dispose() {
    _player.dispose();
  }
}
