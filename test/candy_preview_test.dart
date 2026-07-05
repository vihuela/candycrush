// 糖果渲染预览：flutter test test/candy_preview_test.dart
// 输出 build/icon/candy_preview.png 供视觉检查。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_crush/game/candy_painter.dart';
import 'package:sweet_crush/game/candy_spec.dart';

void main() {
  test('render candy preview grid', () async {
    const cell = 160.0;
    const cols = 4; // none / stripedH / stripedV / wrapped
    final rows = CandyColor.values.length + 1; // + colorBomb 行
    final w = (cell * cols).toInt();
    final h = (cell * rows).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // 游戏内棋盘同款底色
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0xFF241543),
    );
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(20)),
          Paint()
            ..color =
                (r + c).isEven ? const Color(0x21FFFFFF) : const Color(0x0DFFFFFF),
        );
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        if (r < CandyColor.values.length) {
          final color = CandyColor.values[r];
          final special = [
            SpecialType.none,
            SpecialType.stripedH,
            SpecialType.stripedV,
            SpecialType.wrapped,
          ][c];
          CandyPainter.paint(canvas, cell, color, special);
        } else if (c == 0) {
          CandyPainter.paint(
              canvas, cell, CandyColor.red, SpecialType.colorBomb);
        } else if (c == 1) {
          // 冰冻糖：糖果 + 冰壳
          CandyPainter.paint(canvas, cell, CandyColor.blue, SpecialType.none);
          CandyPainter.paintIce(canvas, cell);
        } else if (c == 2) {
          CandyPainter.paintCookie(canvas, cell);
        }
        canvas.restore();
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/icon').createSync(recursive: true);
    File('build/icon/candy_preview.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote build/icon/candy_preview.png');
  });
}
