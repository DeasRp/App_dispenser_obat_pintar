import 'package:flutter_test/flutter_test.dart';
import 'package:dispenser_obat_pintar/core/utils/stock_percentage.dart';

void main() {
  group('calculateStockPercentage', () {
    test('menganggap 30 gram sebagai stok 100 persen', () {
      expect(calculateStockPercentage(30), 100);
    });

    test('menghitung kenaikan 5 gram per kompartemen', () {
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

  group('stockPercentageFromPayload', () {
    test('mengutamakan berat gram dari payload MQTT', () {
      expect(stockPercentageFromPayload({'weight': 30}), 100);
      expect(stockPercentageFromPayload({'weight_grams': '15'}), 50);
    });

    test('tetap menerima payload percent lama', () {
      expect(stockPercentageFromPayload({'percent': 75}), 75);
    });
  });
}
