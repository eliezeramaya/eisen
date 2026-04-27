import 'package:eisen/core/sync/sync_metadata.dart';

abstract interface class SyncableEntity {
  String get localId;
  SyncMetadata get syncMetadata;
}
