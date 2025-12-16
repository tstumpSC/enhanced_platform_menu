import 'package:enhanced_platform_menu/enhanced_platform_menu_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SFSymbolIcon', () {
    test('factory creates SFSymbolIcon subtype', () {
      const icon = EnhancedPlatformMenuIcon.sfSymbol('heart');
      expect(icon, isA<SFSymbolIcon>());
      expect((icon as SFSymbolIcon).name, 'heart');
    });

    test('serialize returns {symbol: <name>}', () {
      const icon = SFSymbolIcon('star.fill');
      expect(icon.serialize(), {'symbol': 'star.fill'});
    });

    test('equality and hashCode based on name', () {
      const a = SFSymbolIcon('bolt');
      const b = SFSymbolIcon('bolt');
      const c = SFSymbolIcon('bolt.fill');

      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('const canonicalization sanity (optional)', () {
      const x1 = SFSymbolIcon('sun.max');
      const x2 = SFSymbolIcon('sun.max');
      // identical is true for const instances with same arguments in the same isolate.
      expect(identical(x1, x2), isTrue);
    });
  });

  group('AssetIcon', () {
    test('factory creates AssetIcon subtype', () {
      const icon = EnhancedPlatformMenuIcon.asset('assets/icon.png');
      expect(icon, isA<AssetIcon>());
      expect((icon as AssetIcon).path, 'assets/icon.png');
    });

    test('default isMonochrome is true', () {
      const icon = AssetIcon('assets/a.png');
      expect(icon.isMonochrome, isTrue);
    });

    test('serialize returns {asset: <path>, isMonochrome: <bool>}', () {
      const mono = AssetIcon('assets/m.png'); // default true
      const color = AssetIcon('assets/c.png', isMonochrome: false);

      expect(mono.serialize(), {'asset': 'assets/m.png', 'isMonochrome': true});
      expect(color.serialize(), {
        'asset': 'assets/c.png',
        'isMonochrome': false,
      });
    });

    test('equality and hashCode based on path + isMonochrome', () {
      const a = AssetIcon('assets/i.png', isMonochrome: true);
      const b = AssetIcon('assets/i.png', isMonochrome: true);
      const c = AssetIcon('assets/i.png', isMonochrome: false);
      const d = AssetIcon('assets/j.png', isMonochrome: true);

      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('const canonicalization sanity (optional)', () {
      const x1 = AssetIcon('assets/same.png');
      const x2 = AssetIcon('assets/same.png');
      expect(identical(x1, x2), isTrue);
    });
  });

  group('Polymorphic serialize', () {
    test('switch in serialize produces correct shape per subtype', () {
      const i1 = EnhancedPlatformMenuIcon.sfSymbol('tray');
      const i2 = EnhancedPlatformMenuIcon.asset(
        'assets/tray.png',
        isMonochrome: false,
      );

      final s1 = i1.serialize();
      final s2 = i2.serialize();

      expect(s1.keys.toSet(), {'symbol'});
      expect(s1['symbol'], 'tray');

      expect(s2.keys.toSet(), {'asset', 'isMonochrome'});
      expect(s2['asset'], 'assets/tray.png');
      expect(s2['isMonochrome'], false);
    });
  });
}
