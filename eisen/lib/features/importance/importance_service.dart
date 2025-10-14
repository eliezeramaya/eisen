
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bandit_service.dart';
import 'models/importance_features.dart';
import 'models/importance_weights.dart';

/// ImportanceService — motor Bayesiano + heurístico con sincronización Supabase.
class ImportanceService {
  final SupabaseClient supabase;
  final Reader read;
  ImportanceService(this.supabase, this.read);

  double importanceScore(ImportanceFeatures f, ImportanceWeights w) {
    final e = f.inTop3 ? 1.0 : 0.0;
    final b = _behavioral(f);
    final c = f.contextFit;
    return w.alpha * e + w.beta * b + w.gamma * c;
  }

  double _behavioral(ImportanceFeatures f) {
    final x = 2.0*f.deadlineSoon + 1.4*f.focus7d + 1.0*f.snoozePenalty +
              0.8*f.editsNorm + 0.6*f.recencyView + 1.0*f.textHint;
    return 1 / (1 + math.exp(-x));
  }

  Future<ImportanceWeights> updateWeights(ImportanceFeatures f, double reward, ImportanceWeights w) async {
    final x = [f.inTop3?1.0:0.0, _behavioral(f), f.contextFit];
    for (int i=0;i<3;i++) {
      for (int j=0;j<3;j++) { w.sigma[i][j] += x[i]*x[j]; }
      w.mu[i] += 0.1*(reward - w.mu[i])*x[i];
    }
    await _syncSupabase(w);
    return w;
  }

  Future<void> _syncSupabase(ImportanceWeights w) async {
    try {
      await supabase.from('importance_weights').upsert({
        'user_id': w.userId,
        'mu': w.mu,
        'sigma': w.sigma,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) { print('Supabase sync error: $e'); }
  }

  List<String> explain(ImportanceFeatures f) {
    final r = <String>[];
    if (f.deadlineSoon>0.7) r.add("Vence pronto");
    if (f.focus7d>0.6) r.add("Le has dedicado tiempo");
    if (f.inTop3) r.add("Elegida en tu check-in");
    if (f.contextFit>0.7) r.add("Coincide con tu horario de foco");
    if (r.isEmpty) r.add("Sugerida por equilibrio semanal");
    return r;
  }
}
