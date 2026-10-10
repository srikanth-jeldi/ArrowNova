import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render approved logo into native iOS icon sizes', () async {
    final bytes = await rootBundle.load('assets/branding/logo.webp');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final source = (await codec.getNextFrame()).image;
    final folder = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final manifest = jsonDecode(
      File('${folder.path}/Contents.json').readAsStringSync(),
    ) as Map;
    for (final item in manifest['images'] as List) {
      final size =
          (double.parse((item['size'] as String).split('x').first) *
                  double.parse((item['scale'] as String).replaceAll('x', '')))
              .round();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff041021), ui.BlendMode.src);
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${folder.path}/${item['filename']}')
          .writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
    source.dispose();
    codec.dispose();
  });
}
