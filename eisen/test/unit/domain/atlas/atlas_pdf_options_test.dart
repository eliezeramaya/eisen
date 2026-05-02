import 'package:eisen/features/atlas/application/export/atlas_paper_size.dart';
import 'package:eisen/features/atlas/application/export/atlas_pdf_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtlasPdfOptions defaults', () {
    const opts = AtlasPdfOptions();

    test('default paper size is ARCH B', () {
      expect(opts.paperSize, AtlasPaperSize.archB);
    });

    test('default orientation is landscape', () {
      expect(opts.orientation, AtlasPaperOrientation.landscape);
    });

    test('includeTitle defaults to true', () {
      expect(opts.includeTitle, isTrue);
    });

    test('includeDate defaults to true', () {
      expect(opts.includeDate, isTrue);
    });

    test('includeLegend defaults to true', () {
      expect(opts.includeLegend, isTrue);
    });

    test('includeInsights defaults to true', () {
      expect(opts.includeInsights, isTrue);
    });

    test('includeFilters defaults to true', () {
      expect(opts.includeFilters, isTrue);
    });

    test('includeTaskSummary defaults to true', () {
      expect(opts.includeTaskSummary, isTrue);
    });

    test('includeTaskList defaults to false', () {
      expect(opts.includeTaskList, isFalse);
    });

    test('includeFooter defaults to true', () {
      expect(opts.includeFooter, isTrue);
    });

    test('pixelRatio defaults to 3.0', () {
      expect(opts.pixelRatio, 3.0);
    });
  });

  group('AtlasPdfOptions.copyWith', () {
    const opts = AtlasPdfOptions();

    test('copyWith changes paper size', () {
      final updated = opts.copyWith(paperSize: AtlasPaperSize.a4);
      expect(updated.paperSize, AtlasPaperSize.a4);
      expect(updated.orientation, opts.orientation);
    });

    test('copyWith changes orientation', () {
      final updated = opts.copyWith(orientation: AtlasPaperOrientation.portrait);
      expect(updated.orientation, AtlasPaperOrientation.portrait);
    });

    test('copyWith enables task list', () {
      final updated = opts.copyWith(includeTaskList: true);
      expect(updated.includeTaskList, isTrue);
    });
  });
}
