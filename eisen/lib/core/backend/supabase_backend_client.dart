import 'package:eisen/core/backend/backend_client.dart';
import 'package:eisen/core/config/app_config.dart';

final class SupabaseBackendClientStub implements BackendClient {
  const SupabaseBackendClientStub({
    required this.config,
  });

  final AppConfig config;

  @override
  String? get currentUserId => null;

  @override
  bool get isConfigured => config.isCloudSyncEnabled;

  @override
  Future<void> initialize() async {
    if (!isConfigured) return;
    throw UnsupportedError(
      'Supabase SDK is not enabled yet. Add supabase_flutter behind this '
      'BackendClient before enabling cloud sync.',
    );
  }

  @override
  Future<void> signInPlaceholder() async {
    throw UnsupportedError('Authentication is not implemented yet.');
  }

  @override
  Future<void> signOutPlaceholder() async {}
}
