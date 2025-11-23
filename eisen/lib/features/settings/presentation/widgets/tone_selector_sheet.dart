import 'package:eisen/core/notifications/notification_sound_service.dart';
import 'package:eisen/features/settings/domain/notification_prefs_controller.dart';
import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet para seleccionar el tono de notificación.
///
/// Muestra lista de tonos disponibles con:
/// - Nombre del tono
/// - Botón de preview (play/stop)
/// - Checkmark para el tono seleccionado
class ToneSelectorSheet extends ConsumerStatefulWidget {
  const ToneSelectorSheet({super.key});

  @override
  ConsumerState<ToneSelectorSheet> createState() => _ToneSelectorSheetState();
}

class _ToneSelectorSheetState extends ConsumerState<ToneSelectorSheet> {
  final NotificationSoundService _soundService = NotificationSoundService();
  NotificationTone? _playingTone;

  @override
  void dispose() {
    _soundService.stopPreview();
    _soundService.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(NotificationTone tone) async {
    if (_playingTone == tone) {
      // Stop current preview
      await _soundService.stopPreview();
      setState(() {
        _playingTone = null;
      });
    } else {
      // Stop previous and play new
      await _soundService.stopPreview();
      if (tone != NotificationTone.defaultTone &&
          tone != NotificationTone.mute) {
        await _soundService.playPreview(tone);
      }
      setState(() {
        _playingTone = tone;
      });

      // Auto-stop after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _playingTone == tone) {
          setState(() {
            _playingTone = null;
          });
        }
      });
    }
  }

  Future<void> _selectTone(NotificationTone tone) async {
    final ctrl = ref.read(notificationPrefsControllerProvider.notifier);
    await ctrl.setNotificationTone(tone);

    // Play preview on selection
    if (tone != NotificationTone.mute && tone != NotificationTone.defaultTone) {
      await _soundService.playPreview(tone);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPrefs = ref.watch(notificationPrefsControllerProvider);
    final currentTone = asyncPrefs.asData?.value.notificationTone ??
        NotificationTone.defaultTone;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seleccionar tono',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // List of tones
          ...NotificationTone.values.map((tone) {
            final isSelected = currentTone == tone;
            final isPlaying = _playingTone == tone;
            final canPreview = tone != NotificationTone.defaultTone &&
                tone != NotificationTone.mute;

            return ListTile(
              leading: Icon(
                _getToneIcon(tone),
                color: isSelected ? colorScheme.primary : null,
              ),
              title: Text(
                tone.labelEs,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: tone == NotificationTone.defaultTone
                  ? const Text('Usa el sonido del sistema')
                  : tone == NotificationTone.mute
                      ? const Text('Sin sonido')
                      : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPreview)
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_circle : Icons.play_circle,
                        color: isPlaying ? colorScheme.secondary : null,
                      ),
                      onPressed: () => _togglePreview(tone),
                      tooltip: isPlaying ? 'Detener' : 'Escuchar',
                    ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              onTap: () => _selectTone(tone),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getToneIcon(NotificationTone tone) {
    return switch (tone) {
      NotificationTone.defaultTone => Icons.notifications,
      NotificationTone.chimeSoft => Icons.wind_power,
      NotificationTone.bellShort => Icons.notifications_active,
      NotificationTone.woodTick => Icons.timer,
      NotificationTone.mute => Icons.notifications_off,
    };
  }
}

/// Muestra el selector de tonos como bottom sheet.
Future<void> showToneSelectorSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const ToneSelectorSheet(),
  );
}
