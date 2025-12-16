import 'package:enhanced_platform_menu/enhanced_platform_menu_delegate.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu_icon.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'enhanced_platform_menu';

  group('EnhancedPlatformMenuDelegate channel calls', () {
    MethodCall? lastCall;
    dynamic lastArguments;

    setUp(() async {
      lastCall = null;
      lastArguments = null;
      // Install a mock handler to capture outbound invokes from Dart to platform.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          lastCall = call;
          lastArguments = call.arguments;
          return null;
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    test(
      'setMenus serializes menus, groups, leafs, shortcuts, checked, identifier/removeDefaults/icons',
          () async {
        // Build a menu with:
        // - A group of 2 items
        // - A leaf item with checked + shortcut
        final group = EnhancedPlatformMenuItemGroup(
          members: const [
            EnhancedPlatformMenuItem(label: 'GroupItem1'),
            EnhancedPlatformMenuItem(label: 'GroupItem2'),
          ],
        );

        final leaf = EnhancedPlatformMenuItem(
          label: 'LeafC',
          checked: true,
          shortcut: const SingleActivator(LogicalKeyboardKey.keyC, control: true),
        );

        final topMenu = EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.file,
          label: 'File',
          menus: [
            group, // -> two leafs + separator (since hasMore)
            leaf,  // then the leaf item
          ],
          removeDefaultItems: true,
        );

        // Also test custom with icon spreading at menu level
        final customMenu = EnhancedPlatformMenu.custom(
          label: 'Custom',
          menus: const [],
          icon: const AssetIcon('assets/gear.png', isMonochrome: false),
        );

        final delegate = EnhancedPlatformMenuDelegate();

        await delegate.setMenus([topMenu, customMenu]);

        // Verify last outbound call
        expect(lastCall?.method, 'Menu.Set');
        expect(lastArguments, isA<Map>());

        // Top-level cast only; nested maps can remain dynamic
        final payload = (lastArguments as Map).cast<String, Object?>();
        expect(payload['menus'], isA<List>());

        final menus = (payload['menus'] as List).cast<Map>();
        expect(menus.length, 2);

        // --- First (standard) menu ---
        final std = menus[0];
        expect(std['kind'], 'menu');
        expect(std['label'], 'File');
        expect(std['identifier'], 'file');      // enum name
        expect(std['removeDefaults'], true);

        final children = (std['children'] as List).cast<Map>();
        // Expected: GroupItem1 leaf, GroupItem2 leaf, separator, LeafC leaf
        expect(children.length, 4);

        expect(children[0]['kind'], 'leaf');
        expect(children[0]['label'], 'GroupItem1');

        expect(children[1]['kind'], 'leaf');
        expect(children[1]['label'], 'GroupItem2');

        expect(children[2]['kind'], 'separator');

        expect(children[3]['kind'], 'leaf');
        expect(children[3]['label'], 'LeafC');
        expect(children[3]['checked'], true);

        // Shortcut shape (don’t over-constrain generics)
        expect(children[3]['shortcut'], isA<Map>());
        final shortcut = children[3]['shortcut'] as Map;
        expect(shortcut.containsKey('shortcutTrigger'), isTrue);
        expect(shortcut.containsKey('shortcutModifiers'), isTrue);

        // --- Second (custom) menu with icon spread ---
        final custom = menus[1];
        expect(custom['kind'], 'menu');
        expect(custom['label'], 'Custom');

        // Your serializer always includes these keys for EnhancedPlatformMenu
        expect(custom['identifier'], isNull);
        expect(custom['removeDefaults'], isFalse);

        // Icon is spread into the map
        expect(custom['asset'], 'assets/gear.png');
        expect(custom['isMonochrome'], false);
      },
    );

    test('clearMenus invokes Menu.Clear', () async {
      final delegate = EnhancedPlatformMenuDelegate();
      await delegate.clearMenus();
      expect(lastCall?.method, 'Menu.Clear');
      expect(lastArguments, isNull);
    });
  });

  group('EnhancedPlatformMenuDelegate debug lock/unlock', () {
    testWidgets('debugLockDelegate allows same context, rejects different context (assert-time)', (
      tester,
    ) async {
      final delegate = EnhancedPlatformMenuDelegate();

      // Two different BuildContexts in the tree
      late BuildContext ctx1;
      late BuildContext ctx2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Builder(
                builder: (c) {
                  ctx1 = c;
                  return const SizedBox();
                },
              ),
              Builder(
                builder: (c) {
                  ctx2 = c;
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      );

      // First lock is fine.
      expect(delegate.debugLockDelegate(ctx1), isTrue);

      // Locking again with the SAME context is allowed.
      expect(delegate.debugLockDelegate(ctx1), isTrue);

      // Locking with a DIFFERENT context should assert-fail (in debug/tests).
      expect(() => delegate.debugLockDelegate(ctx2), throwsAssertionError);

      // Unlock from the original context is allowed.
      expect(delegate.debugUnlockDelegate(ctx1), isTrue);

      // Unlock from a different context should assert-fail if still locked.
      // Re-lock to test that branch:
      delegate.debugLockDelegate(ctx1);
      expect(() => delegate.debugUnlockDelegate(ctx2), throwsAssertionError);

      // Proper unlock
      expect(delegate.debugUnlockDelegate(ctx1), isTrue);
    });
  });
}
