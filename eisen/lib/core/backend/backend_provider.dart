import 'package:eisen/core/backend/backend_client.dart';
import 'package:eisen/core/backend/supabase_backend_client.dart';
import 'package:eisen/core/observability/observability_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backendClientProvider = Provider<BackendClient>((ref) {
  return SupabaseBackendClientStub(
    config: ref.watch(appConfigProvider),
  );
});
