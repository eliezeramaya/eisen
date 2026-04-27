abstract interface class BackendClient {
  bool get isConfigured;
  Future<void> initialize();
  String? get currentUserId;
  Future<void> signInPlaceholder();
  Future<void> signOutPlaceholder();
}
