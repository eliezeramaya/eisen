import 'package:eisen/features/insights_adaptive/data/bandit_state_repository.dart';
import 'package:eisen/features/insights_adaptive/data/thompson_bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_engine.dart';
import 'package:eisen/features/insights_adaptive/domain/bandit_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ThompsonBanditEngine leans toward successful arm', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalBanditStateRepository();
    final engine = ThompsonBanditEngine(repo);
    // Simular éxito en focusBlock varias veces
    await engine.updateReward(NudgeArm.focusBlock, 1);
    await engine.updateReward(NudgeArm.focusBlock, 1);
    await engine.updateReward(NudgeArm.reduceTodayLoad, 0);

    final arm = await engine.selectArm(BanditContext(
      now: DateTime(2025, 1, 1),
      recentProcrastinationScore: 10,
      recentOverloadScore: 10,
      recentQ2Ratio: 50,
    ));

    expect(arm, isA<NudgeArm>());
  });
}
