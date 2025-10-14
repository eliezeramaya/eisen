
import 'dart:math' as math;
import 'models/importance_features.dart';
import 'models/importance_weights.dart';

/// Thompson Sampling Top-2 con guardrails Q2.
class BanditService {
  final math.Random _rng = math.Random();

  ImportanceFeatures pickTop1(List<ImportanceFeatures> feats, ImportanceWeights w, {bool hasUrgentQ2=false}) {
    if (hasUrgentQ2) {
      return feats.firstWhere((f)=>f.isQ2, orElse: ()=>feats.first);
    }
    final top2 = _sampleTop2(feats, w);
    return top2.reduce((a,b)=>a.sampledScore>b.sampledScore?a:b);
  }

  List<ImportanceFeatures> _sampleTop2(List<ImportanceFeatures> feats, ImportanceWeights w) {
    final scored = feats.map((f){
      final base = w.alpha*(f.inTop3?1:0)+w.beta*f.focus7d+w.gamma*f.contextFit;
      final noise = _rng.nextDouble()*0.1 - 0.05;
      return f..sampledScore = base+noise;
    }).toList();
    scored.sort((a,b)=>b.sampledScore.compareTo(a.sampledScore));
    return scored.take(2).toList();
  }
}
