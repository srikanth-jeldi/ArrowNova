import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/clapping_hands.dart';

void main() {
  testWidgets('render two cycles of the actual app hand animation', (
    tester,
  ) async {
    final boundary = GlobalKey();
    Directory('build/clap-preview').createSync(recursive: true);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: const Color(0xFF071B33),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClappingHands(seconds: frame / 20),
                ),
              ),
            ),
          ),
        ),
      );
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/clap-preview/frame-${frame.toString().padLeft(2, '0')}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
