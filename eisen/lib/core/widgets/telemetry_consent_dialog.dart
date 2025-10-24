import 'package:flutter/material.dart';
import 'package:eisen/core/services/telemetry_consent.dart';

/// Privacy-focused consent dialog for telemetry.
///
/// Shows on first launch to request user consent for analytics.
/// Complies with GDPR, CCPA, and privacy best practices.
///
/// Features:
/// - Clear explanation of what data is collected
/// - Easy opt-out option
/// - No dark patterns or pre-checked boxes
/// - Links to privacy policy (if available)
class TelemetryConsentDialog extends StatelessWidget {
  const TelemetryConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help Improve Eisen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'d like to collect anonymous usage data to improve the app.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('What we collect:'),
            const SizedBox(height: 8),
            _buildBullet('Performance metrics (layout speed, loading times)'),
            _buildBullet('Feature usage (which quadrants you use most)'),
            _buildBullet('Anonymous interaction counts'),
            const SizedBox(height: 16),
            const Text('What we DON\'T collect:'),
            const SizedBox(height: 8),
            _buildBullet('Task content or titles', isNegative: true),
            _buildBullet('Personal information', isNegative: true),
            _buildBullet('Location data', isNegative: true),
            const SizedBox(height: 16),
            const Text(
              'Task IDs are hashed (one-way encryption) so they cannot be traced back to you.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can change this anytime in Settings.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await TelemetryConsent.denyConsent();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('No Thanks'),
        ),
        FilledButton(
          onPressed: () async {
            await TelemetryConsent.grantConsent();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }

  Widget _buildBullet(String text, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNegative ? Icons.block : Icons.check_circle_outline,
            size: 16,
            color: isNegative ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Show consent dialog if needed (first launch).
  static Future<void> showIfNeeded(BuildContext context) async {
    final isFirstLaunch = await TelemetryConsent.initialize();
    
    if (isFirstLaunch && context.mounted) {
      // Wait a bit for app to settle before showing dialog
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const TelemetryConsentDialog(),
        );
      }
    }
  }
}
