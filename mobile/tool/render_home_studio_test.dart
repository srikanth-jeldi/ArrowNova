import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/decor_collection.dart';
import 'package:arrownova/garden/home_decor_screen.dart';

void main() {
  testWidgets('render three room palettes and real furniture catalogue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in {
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    for (var level = 1; level <= 3; level++) {
      final p = PlayerProgress();
      p.homeDecor.level = level;
      final collection = [0, 2, 3][level - 1];
      for (var i = 0; i < 7; i++) {
        final item = DecorPiece(i, collection);
        if (item.premium) {
          for (var n = 0; n < 3; n++) {
            p.homeDecor.current.reward(item);
          }
        }
        p.homeDecor.current.place(item);
      }
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(level),
          debugShowCheckedModeBanner: false,
          home: HomeDecorScreen(progress: p, onChanged: () {}, onBack: () {}),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(HomeDecorScreen));
        for (final asset in [
          'room',
          'room_1',
          'room_2',
          'collection_0',
          'collection_1',
          'collection_2',
          'collection_3',
        ]) {
          if (!context.mounted) return;
          await precacheImage(
            asset.startsWith('room')
                ? ResizeImage(
                    AssetImage('assets/art/decor/$asset.webp'),
                    width: 1024,
                  )
                : AssetImage('assets/art/decor/$asset.webp'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../design/previews/home-studio-$level.png'),
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('compare the three actual room themes', (tester) async {
    tester.view.physicalSize = const Size(1080, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rooms = <DecorRoom>[];
    for (final style in [0, 2, 3]) {
      final room = DecorRoom();
      for (var i = 0; i < 7; i++) {
        final piece = DecorPiece(i, style);
        if (piece.premium) {
          for (var n = 0; n < 3; n++) {
            room.reward(piece);
          }
        }
        room.place(piece);
      }
      rooms.add(room);
    }
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'ArrowNovaSans'),
        home: Scaffold(
          backgroundColor: const Color(0xFFF8F6F0),
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            decorRoomNames[i],
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DecorRoomScene(room: rooms[i], level: i + 1),
                          const SizedBox(height: 10),
                          Text(
                            ['Ivory + oak', 'Blush + rose', 'Blue + ivory'][i],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold));
      for (final asset in ['room', 'room_1', 'room_2']) {
        if (!context.mounted) return;
        await precacheImage(
          ResizeImage(AssetImage('assets/art/decor/$asset.webp'), width: 1024),
          context,
        );
      }
      for (final n in [0, 2, 3]) {
        if (!context.mounted) return;
        await precacheImage(
          AssetImage('assets/art/decor/collection_$n.webp'),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/previews/home-studio-themes.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
