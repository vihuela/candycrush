// 图标生成脚本：flutter test test/icon_gen_test.dart
// 用真实 Skia 引擎离屏渲染 App 图标，输出到 build/icon/。
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweet_crush/game/candy_painter.dart';
import 'package:sweet_crush/game/candy_spec.dart';

const _size = 1024.0;

void main() {
  test('generate app icons', () async {
    final dir = Directory('build/icon');
    dir.createSync(recursive: true);

    // 完整图标（含背景，用于旧版 launcher）
    await _render('build/icon/icon_full.png', withBackground: true);
    // 前景层（透明底，用于自适应图标，糖果缩进安全区）
    await _render('build/icon/icon_fg.png',
        withBackground: false, scale: 0.62);
    // 自适应背景层
    await _renderBackground('build/icon/icon_bg.png');
  });
}

Future<void> _render(String path,
    {required bool withBackground, double scale = 1.0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (withBackground) {
    _paintBackground(canvas);
  }

  canvas.save();
  canvas.translate(_size / 2, _size / 2);
  canvas.scale(scale);

  // 主体：包装糖，微微旋转更俏皮
  canvas.save();
  canvas.rotate(-pi / 14);
  CandyPainter.paint(canvas, _size * 0.56, CandyColor.red, SpecialType.wrapped);
  canvas.restore();

  // 点缀小糖果
  canvas.save();
  canvas.translate(-_size * 0.345, _size * 0.315);
  canvas.rotate(pi / 8);
  CandyPainter.paint(
      canvas, _size * 0.16, CandyColor.yellow, SpecialType.none);
  canvas.restore();

  canvas.save();
  canvas.translate(_size * 0.345, -_size * 0.30);
  canvas.rotate(-pi / 10);
  CandyPainter.paint(canvas, _size * 0.14, CandyColor.blue, SpecialType.none);
  canvas.restore();

  // 星光点缀
  _sparkle(canvas, Offset(-_size * 0.27, -_size * 0.30), _size * 0.045);
  _sparkle(canvas, Offset(_size * 0.33, _size * 0.20), _size * 0.03);
  _sparkle(canvas, Offset(_size * 0.05, _size * 0.36), _size * 0.022);

  canvas.restore();

  await _save(recorder, path);
}

Future<void> _renderBackground(String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintBackground(canvas, rounded: false);
  await _save(recorder, path);
}

void _paintBackground(Canvas canvas, {bool rounded = true}) {
  final rect = Rect.fromLTWH(0, 0, _size, _size);
  final rrect = rounded
      ? RRect.fromRectAndRadius(rect, const Radius.circular(_size * 0.22))
      : RRect.fromRectAndRadius(rect, Radius.zero);
  // 紫色渐变底
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        const [Color(0xFF3B1866), Color(0xFF5B2C96), Color(0xFF3A3D8F)],
        const [0.0, 0.55, 1.0],
      ),
  );
  // 顶部径向柔光
  canvas.save();
  canvas.clipRRect(rrect);
  canvas.drawCircle(
    Offset(_size * 0.30, _size * 0.12),
    _size * 0.55,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(_size * 0.30, _size * 0.12),
        _size * 0.55,
        const [Color(0x40FF9FF3), Color(0x00FF9FF3)],
      ),
  );
  canvas.restore();
}

void _sparkle(Canvas canvas, Offset at, double r) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4;
    final d = i.isEven ? r : r * 0.36;
    final p = at + Offset(cos(a) * d, sin(a) * d);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = const Color(0xE6FFFFFF));
}

Future<void> _save(ui.PictureRecorder recorder, String path) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path');
}
