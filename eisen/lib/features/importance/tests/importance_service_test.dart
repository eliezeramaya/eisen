
import 'package:flutter_test/flutter_test.dart';
import '../importance_service.dart';
import '../models/importance_features.dart';
import '../models/importance_weights.dart';

void main(){
  test('importanceScore > for urgent tasks', (){
    final service = ImportanceService(FakeSupabase(), (_)=>null);
    final f1 = ImportanceFeatures(taskId:'1', deadlineSoon:0.9);
    final f2 = ImportanceFeatures(taskId:'2', deadlineSoon:0.1);
    final w = ImportanceWeights(userId:'u1');
    final s1 = service.importanceScore(f1,w);
    final s2 = service.importanceScore(f2,w);
    expect(s1>s2,true);
  });
}

class FakeSupabase { dynamic from(String _) => FakeTable(); }
class FakeTable { Future<void> upsert(Map<String,dynamic> _) async{} }
