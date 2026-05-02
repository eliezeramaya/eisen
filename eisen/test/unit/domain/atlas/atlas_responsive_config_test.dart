import 'package:eisen/features/atlas/domain/atlas_responsive_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact inicia leyenda colapsada y desktop expandida', () {
    final compact = atlasResponsiveConfigForWidth(390);
    final desktop = atlasResponsiveConfigForWidth(1100);

    expect(compact.showLegendExpandedByDefault, isFalse);
    expect(desktop.showLegendExpandedByDefault, isTrue);
  });

  test('compact usa gap mayor que desktop para tactilidad', () {
    final compact = atlasResponsiveConfigForWidth(390);
    final large = atlasResponsiveConfigForWidth(1440);

    expect(compact.tileGap, greaterThan(large.tileGap));
  });

  test('umbral painter cambia por device class', () {
    final compact = atlasResponsiveConfigForWidth(390);
    final large = atlasResponsiveConfigForWidth(1440);

    expect(
      compact.maxWidgetTilesBeforePainter,
      lessThan(large.maxWidgetTilesBeforePainter),
    );
  });
}
