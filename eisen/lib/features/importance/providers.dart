
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'importance_service.dart';
import 'bandit_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref)=>Supabase.instance.client);
final banditProvider = Provider<BanditService>((ref)=>BanditService());
final importanceServiceProvider = Provider<ImportanceService>((ref){
  final client = ref.read(supabaseClientProvider);
  return ImportanceService(client, ref.read);
});
