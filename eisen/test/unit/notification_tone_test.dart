import 'package:eisen/features/settings/domain/notification_tone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationTone', () {
    group('labelEs', () {
      test('returns correct Spanish labels', () {
        expect(NotificationTone.defaultTone.labelEs, 'Predeterminado');
        expect(NotificationTone.chimeSoft.labelEs, 'Campanada suave');
        expect(NotificationTone.bellShort.labelEs, 'Campana corta');
        expect(NotificationTone.woodTick.labelEs, 'Tick de madera');
        expect(NotificationTone.mute.labelEs, 'Silencio');
      });
    });

    group('labelEn', () {
      test('returns correct English labels', () {
        expect(NotificationTone.defaultTone.labelEn, 'Default');
        expect(NotificationTone.chimeSoft.labelEn, 'Soft Chime');
        expect(NotificationTone.bellShort.labelEn, 'Short Bell');
        expect(NotificationTone.woodTick.labelEn, 'Wood Tick');
        expect(NotificationTone.mute.labelEn, 'Mute');
      });
    });

    group('assetPath', () {
      test('returns null for defaultTone', () {
        expect(NotificationTone.defaultTone.assetPath, isNull);
      });

      test('returns null for mute', () {
        expect(NotificationTone.mute.assetPath, isNull);
      });

      test('returns correct asset paths for custom tones', () {
        expect(NotificationTone.chimeSoft.assetPath,
            'assets/sounds/chime_soft.mp3');
        expect(NotificationTone.bellShort.assetPath,
            'assets/sounds/bell_short.mp3');
        expect(
            NotificationTone.woodTick.assetPath, 'assets/sounds/wood_tick.mp3');
      });
    });

    group('id', () {
      test('returns correct IDs for all tones', () {
        expect(NotificationTone.defaultTone.id, 'default');
        expect(NotificationTone.chimeSoft.id, 'chime_soft');
        expect(NotificationTone.bellShort.id, 'bell_short');
        expect(NotificationTone.woodTick.id, 'wood_tick');
        expect(NotificationTone.mute.id, 'mute');
      });

      test('all IDs are unique', () {
        final ids = NotificationTone.values.map((t) => t.id).toList();
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length,
            reason: 'All IDs should be unique');
      });
    });

    group('fromId', () {
      test('parses valid IDs correctly', () {
        expect(
            NotificationToneX.fromId('default'), NotificationTone.defaultTone);
        expect(
            NotificationToneX.fromId('chime_soft'), NotificationTone.chimeSoft);
        expect(
            NotificationToneX.fromId('bell_short'), NotificationTone.bellShort);
        expect(
            NotificationToneX.fromId('wood_tick'), NotificationTone.woodTick);
        expect(NotificationToneX.fromId('mute'), NotificationTone.mute);
      });

      test('returns defaultTone for invalid ID', () {
        expect(
            NotificationToneX.fromId('invalid'), NotificationTone.defaultTone);
        expect(NotificationToneX.fromId(''), NotificationTone.defaultTone);
      });

      test('returns defaultTone for legacy values', () {
        // Test backwards compatibility
        expect(NotificationToneX.fromId('chime'), NotificationTone.defaultTone);
        expect(NotificationToneX.fromId('bell'), NotificationTone.defaultTone);
      });
    });

    group('serialization round-trip', () {
      test('all tones can be serialized and deserialized', () {
        for (final tone in NotificationTone.values) {
          final id = tone.id;
          final parsed = NotificationToneX.fromId(id);
          expect(parsed, tone,
              reason: 'Round-trip for ${tone.name} should preserve value');
        }
      });
    });
  });
}
