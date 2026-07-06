# Google Play 提审素材 / Store Submission Assets

Sweet Crush 的 Google Play 商店图形素材。所有图片均复用游戏内的矢量渲染代码
（`CandyPainter` / 调色板 / Fredoka 字体）排版生成，与游戏实际美术完全一致。

## 文件清单

| 文件 | 用途 | 尺寸 | 格式 |
|---|---|---|---|
| `phone_portrait_1_hero.jpg` | 手机截图 1：Logo + 糖果爆发主视觉 | 1080x1920 | JPEG |
| `phone_portrait_2_gameplay.jpg` | 手机截图 2：对局画面（HUD/棋盘/道具） | 1080x1920 | JPEG |
| `phone_portrait_3_specials.jpg` | 手机截图 3：特殊糖果介绍 | 1080x1920 | JPEG |
| `phone_portrait_4_modes.jpg` | 手机截图 4：三种模式 + 障碍 + 星级 | 1080x1920 | JPEG |
| `phone_landscape_1_hero.jpg` | 横版截图 1：Logo + 卖点 + 倾斜棋盘 | 1920x1080 | JPEG |
| `phone_landscape_2_combos.jpg` | 横版截图 2：连锁反应特效 | 1920x1080 | JPEG |
| `feature_graphic_1024x500.jpg` | Feature Graphic（上架必需） | 1024x500 | JPEG |
| `app_icon_512.png` | 应用图标（上架必需，与 App 启动图标同构图） | 512x512 | PNG |
| `masters_png/` | PNG 无损母版（截图勿直接上传，含 Alpha 通道） | — | PNG |

## Play 商店要求对照（2026）

- 手机截图：最少 2 张、最多 8 张；每边 320–3840px，长宽比不超过 2:1；
  推荐 1080x1920（竖）/ 1920x1080（横）✅
- 格式：JPEG 或 24 位 PNG（不允许 Alpha 通道）——因此上传 `*.jpg` ✅
- 单文件 ≤ 8MB ✅
- Feature Graphic 1024x500 为上架必需项 ✅
- 应用图标：512x512、PNG/JPEG、≤1MB；构图与启动图标（`test/icon_gen_test.dart`）
  完全一致，但输出全出血方形——Google Play 会自动叠加 ~20% 圆角遮罩，
  不能预先烘焙圆角 ✅
- 若想获得 Google Play 推荐位资格：至少 4 张 16:9 或 9:16、1080px+ 截图 ✅
- 文案避免 "#1 / Best / Install Now" 等违禁用语 ✅

参考：
- [Play Console 官方帮助：预览素材](https://support.google.com/googleplay/android-developer/answer/9866151)

## 重新生成

素材由 `test/store_screenshots_test.dart` 生成（复用游戏渲染代码，可随美术迭代随时重出）：

```bash
STORE_SHOTS=1 flutter test test/store_screenshots_test.dart   # 生成 PNG 母版
cd store_submission
for f in masters_png/*.png; do
  sips -s format jpeg -s formatOptions best "$f" --out "$(basename "$f" .png).jpg" >/dev/null
done
```

> 上传 Play Console 时记得为每张截图填写 alt text（≤140 字符）以提升无障碍体验。
