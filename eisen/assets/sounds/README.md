# Notification Sounds

This directory contains sound files for notification tones in Eisen.

## Required Files

The following sound files need to be added to this directory:

1. **chime_soft.mp3** - A soft, subtle chime sound
   - Duration: ~1-2 seconds
   - Format: MP3
   - Volume: Medium-soft

2. **bell_short.mp3** - A short bell notification sound
   - Duration: ~1 second
   - Format: MP3
   - Volume: Medium

3. **wood_tick.mp3** - A minimalist wood tick sound
   - Duration: ~0.5-1 second
   - Format: MP3
   - Volume: Soft

## File Requirements

- Format: MP3 (recommended for cross-platform compatibility)
- Sample Rate: 44.1 kHz or 48 kHz
- Bit Rate: 128-192 kbps
- Max Duration: 3 seconds
- Max File Size: 100 KB per file

## Android Requirements

For Android notifications to work properly, the same audio files must also be placed in:
`android/app/src/main/res/raw/`

With the following names (no file extension):
- `chime_soft.mp3` → `chime_soft`
- `bell_short.mp3` → `bell_short`
- `wood_tick.mp3` → `wood_tick`

## Sources for Free Sounds

You can find royalty-free notification sounds at:
- [Freesound.org](https://freesound.org/)
- [Zapsplat.com](https://www.zapsplat.com/)
- [Soundbible.com](http://soundbible.com/)

## Implementation

These sounds are referenced in:
- `lib/features/settings/domain/notification_tone.dart` (enum with asset paths)
- `lib/core/notifications/notification_sound_service.dart` (playback service)
- `lib/features/settings/presentation/widgets/tone_selector_sheet.dart` (UI selector)
