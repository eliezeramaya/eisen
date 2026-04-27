import 'package:eisen/features/classification/data/datasources/classification_local_datasource.dart';
import 'package:eisen/features/classification/data/models/rule_suggestion_model.dart';
import 'package:eisen/features/classification/domain/entities/classification_rule.dart';
import 'package:eisen/features/classification/domain/entities/rule_suggestion.dart';
import 'package:eisen/features/classification/domain/enums/rule_match_type.dart';
import 'package:eisen/features/classification/domain/enums/rule_priority.dart';
import 'package:eisen/features/classification/domain/enums/suggestion_status.dart';
import 'package:eisen/features/eisen_matrix/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists and restores rule suggestions with status', () async {
    final datasource = ClassificationLocalDatasource();
    final suggestion = RuleSuggestion(
      id: 'suggestion-1',
      detectedPattern: 'rosario',
      suggestedRule: ClassificationRule(
        id: 'rule-1',
        name: 'Cliente Rosario',
        keywords: const <String>['rosario'],
        matchType: RuleMatchType.contains,
        targetCategoryId: 'work',
        targetQuadrant: Quadrant.q2,
        priority: RulePriority.high,
      ),
      confidence: 0.82,
      status: SuggestionStatus.dismissed,
      createdAt: DateTime.parse('2026-04-25T10:00:00.000Z'),
    );

    await datasource.saveRuleSuggestions(
      <RuleSuggestionModel>[RuleSuggestionModel.fromEntity(suggestion)],
    );
    final loaded = await datasource.loadRuleSuggestions();

    expect(loaded, hasLength(1));
    expect(loaded.single.detectedPattern, 'rosario');
    expect(loaded.single.status, SuggestionStatus.dismissed);
    expect(loaded.single.suggestedRule.targetCategoryId, 'work');
    expect(loaded.single.suggestedRule.targetQuadrant, Quadrant.q2);
  });
}
