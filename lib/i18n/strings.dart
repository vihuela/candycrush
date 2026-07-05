import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言。
enum AppLang { zhHans, zhHant, en, ja, ko }

extension AppLangInfo on AppLang {
  /// 语言的本族名称（切换菜单固定显示，不随界面语言变化）。
  String get nativeName => switch (this) {
        AppLang.zhHans => '简体中文',
        AppLang.zhHant => '繁體中文',
        AppLang.en => 'English',
        AppLang.ja => '日本語',
        AppLang.ko => '한국어',
      };

  Locale get locale => switch (this) {
        AppLang.zhHans =>
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        AppLang.zhHant =>
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        AppLang.en => const Locale('en'),
        AppLang.ja => const Locale('ja'),
        AppLang.ko => const Locale('ko'),
      };
}

/// 全局语言状态：首次启动跟随设备语言（英文兜底），可在 App 内切换并持久化。
class Lang {
  static const _prefKey = 'app_lang';
  static final ValueNotifier<AppLang> notifier = ValueNotifier(AppLang.en);

  static L get t => _tables[notifier.value]!;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      notifier.value = AppLang.values.firstWhere(
        (l) => l.name == saved,
        orElse: () => AppLang.en,
      );
      return;
    }
    notifier.value = _detectDevice();
  }

  static AppLang _detectDevice() {
    final device = PlatformDispatcher.instance.locale;
    switch (device.languageCode) {
      case 'zh':
        // zh-Hant / 台湾香港澳门 -> 繁体，其余中文 -> 简体
        final traditional = device.scriptCode == 'Hant' ||
            const {'TW', 'HK', 'MO'}.contains(device.countryCode);
        return traditional ? AppLang.zhHant : AppLang.zhHans;
      case 'ja':
        return AppLang.ja;
      case 'ko':
        return AppLang.ko;
      case 'en':
        return AppLang.en;
      default:
        return AppLang.en; // 英文兜底
    }
  }

  static Future<void> set(AppLang lang) async {
    notifier.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.name);
  }
}

/// 界面文案表。
class L {
  const L({
    required this.subtitle,
    required this.modeClassic,
    required this.modeCollect,
    required this.modeTimed,
    required this.timedTitle,
    required this.timedDesc,
    required this.bestPrefix,
    required this.noRecord,
    required this.startChallenge,
    required this.levelLabel,
    required this.goalLabel,
    required this.hammer,
    required this.bomb,
    required this.shuffle,
    required this.tapTarget,
    required this.winTitle,
    required this.allClearTitle,
    required this.loseTitle,
    required this.timeUpTitle,
    required this.newRecordTitle,
    required this.scoreLabel,
    required this.nextLevel,
    required this.backToLevels,
    required this.retry,
    required this.playAgain,
    required this.replay,
    required this.back,
    required this.comboWords,
    required this.shuffleNotice,
    required this.settings,
    required this.language,
    required this.terms,
    required this.privacy,
    required this.comingSoon,
  });

  final String subtitle;
  final String modeClassic;
  final String modeCollect;
  final String modeTimed;
  final String timedTitle;
  final String Function(int seconds) timedDesc;
  final String bestPrefix;
  final String noRecord;
  final String startChallenge;
  final String Function(int n) levelLabel;
  final String Function(int n) goalLabel;
  final String hammer;
  final String bomb;
  final String shuffle;
  final String tapTarget;
  final String winTitle;
  final String allClearTitle;
  final String loseTitle;
  final String timeUpTitle;
  final String newRecordTitle;
  final String scoreLabel;
  final String nextLevel;
  final String backToLevels;
  final String retry;
  final String playAgain;
  final String replay;
  final String back;
  final List<String> comboWords;
  final String shuffleNotice;
  final String settings;
  final String language;
  final String terms;
  final String privacy;
  final String comingSoon;
}

final Map<AppLang, L> _tables = {
  AppLang.zhHans: L(
    subtitle: '甜蜜消消乐',
    modeClassic: '经典',
    modeCollect: '收集',
    modeTimed: '限时',
    timedTitle: '限时挑战',
    timedDesc: (s) => '$s 秒内尽可能多得分\n连锁和特殊糖是高分关键！',
    bestPrefix: '最佳纪录',
    noRecord: '暂无纪录',
    startChallenge: '开始挑战',
    levelLabel: (n) => '第 $n 关',
    goalLabel: (n) => '目标 $n',
    hammer: '锤子',
    bomb: '炸弹',
    shuffle: '洗牌',
    tapTarget: '点击目标',
    winTitle: '🎉 过关啦！',
    allClearTitle: '👑 全部通关！',
    loseTitle: '😢 差一点点',
    timeUpTitle: '⏱️ 时间到！',
    newRecordTitle: '🏆 新纪录！',
    scoreLabel: '得分',
    nextLevel: '下一关  ▶',
    backToLevels: '返回选关',
    retry: '重试',
    playAgain: '再来一局',
    replay: '重玩',
    back: '返回',
    comboWords: ['好！', '妙极了！', '太棒了！', '无敌连锁!'],
    shuffleNotice: '无可消除，洗牌！',
    settings: '设置',
    language: '语言',
    terms: '服务协议',
    privacy: '隐私政策',
    comingSoon: '更多关卡即将推出',
  ),
  AppLang.zhHant: L(
    subtitle: '甜蜜消消樂',
    modeClassic: '經典',
    modeCollect: '收集',
    modeTimed: '限時',
    timedTitle: '限時挑戰',
    timedDesc: (s) => '$s 秒內盡可能多得分\n連鎖和特殊糖是高分關鍵！',
    bestPrefix: '最佳紀錄',
    noRecord: '暫無紀錄',
    startChallenge: '開始挑戰',
    levelLabel: (n) => '第 $n 關',
    goalLabel: (n) => '目標 $n',
    hammer: '錘子',
    bomb: '炸彈',
    shuffle: '洗牌',
    tapTarget: '點擊目標',
    winTitle: '🎉 過關啦！',
    allClearTitle: '👑 全部通關！',
    loseTitle: '😢 差一點點',
    timeUpTitle: '⏱️ 時間到！',
    newRecordTitle: '🏆 新紀錄！',
    scoreLabel: '得分',
    nextLevel: '下一關  ▶',
    backToLevels: '返回選關',
    retry: '重試',
    playAgain: '再來一局',
    replay: '重玩',
    back: '返回',
    comboWords: ['好！', '妙極了！', '太棒了！', '無敵連鎖!'],
    shuffleNotice: '無可消除，洗牌！',
    settings: '設定',
    language: '語言',
    terms: '服務條款',
    privacy: '隱私政策',
    comingSoon: '更多關卡即將推出',
  ),
  AppLang.en: L(
    subtitle: 'Sweet Match-3 Fun',
    modeClassic: 'Classic',
    modeCollect: 'Collect',
    modeTimed: 'Timed',
    timedTitle: 'Timed Challenge',
    timedDesc: (s) =>
        'Score as much as you can in $s seconds.\nCascades & special candies are key!',
    bestPrefix: 'Best',
    noRecord: 'No record yet',
    startChallenge: 'Start',
    levelLabel: (n) => 'Level $n',
    goalLabel: (n) => 'Goal $n',
    hammer: 'Hammer',
    bomb: 'Bomb',
    shuffle: 'Shuffle',
    tapTarget: 'Tap a target',
    winTitle: '🎉 Level Clear!',
    allClearTitle: '👑 All Clear!',
    loseTitle: '😢 So Close!',
    timeUpTitle: "⏱️ Time's Up!",
    newRecordTitle: '🏆 New Record!',
    scoreLabel: 'Score',
    nextLevel: 'Next  ▶',
    backToLevels: 'Level Select',
    retry: 'Retry',
    playAgain: 'Play Again',
    replay: 'Replay',
    back: 'Back',
    comboWords: ['Good!', 'Great!', 'Awesome!', 'Unstoppable!'],
    shuffleNotice: 'No moves — shuffling!',
    settings: 'Settings',
    language: 'Language',
    terms: 'Terms of Service',
    privacy: 'Privacy Policy',
    comingSoon: 'More levels coming soon',
  ),
  AppLang.ja: L(
    subtitle: 'スイートマッチ3',
    modeClassic: 'クラシック',
    modeCollect: 'コレクト',
    modeTimed: 'タイム',
    timedTitle: 'タイムアタック',
    timedDesc: (s) => '$s 秒間でハイスコアを目指そう\n連鎖とスペシャルキャンディがカギ！',
    bestPrefix: 'ベスト記録',
    noRecord: '記録なし',
    startChallenge: 'スタート',
    levelLabel: (n) => 'レベル $n',
    goalLabel: (n) => '目標 $n',
    hammer: 'ハンマー',
    bomb: 'ボム',
    shuffle: 'シャッフル',
    tapTarget: 'ターゲットをタップ',
    winTitle: '🎉 クリア！',
    allClearTitle: '👑 全クリア！',
    loseTitle: '😢 おしい！',
    timeUpTitle: '⏱️ タイムアップ！',
    newRecordTitle: '🏆 新記録！',
    scoreLabel: 'スコア',
    nextLevel: '次へ  ▶',
    backToLevels: 'レベル選択',
    retry: 'リトライ',
    playAgain: 'もう一度',
    replay: '再挑戦',
    back: '戻る',
    comboWords: ['いいね！', 'すごい！', '最高！', '無敵コンボ!'],
    shuffleNotice: '手詰まり！シャッフル！',
    settings: '設定',
    language: '言語',
    terms: '利用規約',
    privacy: 'プライバシーポリシー',
    comingSoon: '新レベルは近日公開',
  ),
  AppLang.ko: L(
    subtitle: '스위트 매치3',
    modeClassic: '클래식',
    modeCollect: '수집',
    modeTimed: '타임',
    timedTitle: '타임 챌린지',
    timedDesc: (s) => '$s초 안에 최대한 득점하세요\n연쇄와 특수 캔디가 핵심!',
    bestPrefix: '최고 기록',
    noRecord: '기록 없음',
    startChallenge: '시작하기',
    levelLabel: (n) => '레벨 $n',
    goalLabel: (n) => '목표 $n',
    hammer: '망치',
    bomb: '폭탄',
    shuffle: '섞기',
    tapTarget: '대상을 탭하세요',
    winTitle: '🎉 클리어!',
    allClearTitle: '👑 전체 클리어!',
    loseTitle: '😢 아쉬워요!',
    timeUpTitle: '⏱️ 시간 종료!',
    newRecordTitle: '🏆 신기록!',
    scoreLabel: '점수',
    nextLevel: '다음  ▶',
    backToLevels: '레벨 선택',
    retry: '재도전',
    playAgain: '다시 하기',
    replay: '다시 플레이',
    back: '돌아가기',
    comboWords: ['좋아요!', '대단해요!', '굉장해요!', '무적 콤보!'],
    shuffleNotice: '이동 불가 — 섞는 중!',
    settings: '설정',
    language: '언어',
    terms: '서비스 약관',
    privacy: '개인정보 처리방침',
    comingSoon: '새 레벨이 곧 출시됩니다',
  ),
};
