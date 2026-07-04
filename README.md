# 🍬 Sweet Crush 甜蜜消消乐

Candy Crush 风格的三消游戏，Flutter + Flame 引擎实现，产物为 Android APK。

## 玩法特性

- **8×8 棋盘三消**：滑动或点选交换，支持连锁级联
- **特殊糖果**：4 连 → 条纹糖（清行/列）；L/T 形 → 包装糖（3×3 爆炸）；5 连 → 彩色炸弹（清同色）；特殊糖两两组合触发大招（双彩球全屏清除等）
- **道具**：🔨 锤子（敲单格）、💣 炸弹（3×3）、🔄 洗牌
- **10 个关卡**：步数限制 + 目标分数，1~3 星评级，进度本地存档
- **击打感**：爆裂粒子、条纹光束、冲击波、闪电链、屏幕震动、触感反馈、连锁飘字、程序合成音效
- **纯矢量美术**：糖果由 7 层光影质感代码绘制（投影/渐变/反弹光/AO/边缘光/双高光），无第三方素材

## 构建

```bash
flutter pub get
flutter test          # 核心逻辑单测
flutter build apk --release
# 产物: build/app/outputs/flutter-apk/app-release.apk
```

## 结构

```
lib/
  game/
    board.dart          # 纯 Dart 三消引擎（匹配/重力/特殊糖/洗牌）
    match_game.dart     # Flame 主游戏（输入/结算循环/特效调度）
    candy_painter.dart  # 糖果矢量渲染
    candy_component.dart# 糖果组件动画（下落弹跳/交换/消除）
    effects.dart        # 粒子/光束/冲击波/闪电/飘字
    sfx.dart            # 音效管理
    levels.dart         # 关卡配置
  ui/                   # 关卡选择/对局 HUD/结算弹窗
tool/gen_sfx.py         # 程序化合成音效 WAV
```

## 音效

`assets/audio/*.wav` 由 `tool/gen_sfx.py` 纯 Python 合成（正弦扫频 + 噪声包络），可自行调参重新生成：

```bash
python3 tool/gen_sfx.py
```
