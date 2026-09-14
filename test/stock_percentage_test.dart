import 'package:flutter_test/flutter_test.dart';
import 'package:dispenser_obat_pintar/core/utils/stock_percentage.dart';

void main() {
  group('calculateStockPercentage', () {
    test('menganggap 30 gram sebagai stok 100 persen', () {
      expect(calculateStockPercentage(30), 100);
    });

    test('menghitung perubahan berat terhadap stok penuh 30 gram', () {
      expect(calculateStockPercentage(0), 0);
      expect(calculateStockPercentage(5), 17);
      expect(calculateStockPercentage(10), 33);
      expect(calculateStockPercentage(15), 50);
      expect(calculateStockPercentage(20), 67);
      expect(calculateStockPercentage(25), 83);
    });

    test('membatasi hasil ke rentang 0 sampai 100', () {
      expect(calculateStockPercentage(-1), 0);
      expect(calculateStockPercentage(35), 100);
    });
  });

  group('stabilizeStockDisplayPercent', () {
    test('membulatkan visual stok ke kelipatan 5 persen', () {
      expect(stabilizeStockDisplayPercent(71), 70);
      expect(stabilizeStockDisplayPercent(73), 75);
      expect(stabilizeStockDisplayPercent(98), 100);
    });
  });

  group('stockPercentageFromPayload', () {
    test('mengutamakan berat gram dari payload MQTT', () {
      expect(stockPercentageFromPayload({'weight': 30}), 100);
      expect(stockPercentageFromPayload({'weight_grams': '15'}), 50);
    });

    test('tetap menerima payload percent lama dan menstabilkan visual', () {
      expect(stockPercentageFromPayload({'percent': 75}), 75);
      expect(stockPercentageFromPayload({'percent': 73}), 75);
    });
  });
}
