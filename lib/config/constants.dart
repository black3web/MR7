class AppConstants {
  // App Info
  static const String appName        = 'MR7';
  static const String appFullName    = 'MR7 Chat';
  static const String appVersion     = '2.0.0';
  static const String appBuildNumber = '2';

  // Developer account
  static const String devName        = 'جلال';
  static const String devUsername    = 'a1';
  static const String devPasswordRaw = '5cd9e55dcaf491d32289b848adeb216e';
  static const String devId          = '000000000000001';
  static const String devWebsite     = 'https://black3web.github.io/Blackweb/';
  static const String devTelegram    = 'https://t.me/swc_t';

  // ── AI API Endpoints ──────────────────────────────────────────────────
  // Gemini / Kilwa Chat
  static const String _geminiUrl      = 'http://de3.bot-hosting.net:21007/kilwa-chat';
  // GPT Image 2 (NEW)
  static const String _gptImg2Url     = 'http://de3.bot-hosting.net:21007/kilwa-gpt-img';
  // Nano Banana 2 image gen
  static const String _imageNanoUrl   = 'http://de3.bot-hosting.net:21007/kilwa-img';
  // Kilwa Video (legacy)
  static const String _kilwaVideoUrl  = 'http://de3.bot-hosting.net:21007/kilwa-video';
  // DeepSeek (updated URL)
  static const String _deepSeekUrl    = 'https://zecora0.serv00.net/deepseek.php';
  // NanoBanana Pro (edit/create)
  static const String _nanoBanaProUrl = 'https://zecora0.serv00.net/ai/NanoBanana.php';
  // Seedance video gen (updated URL)
  static const String _seedanceUrl    = 'https://zecora0.serv00.net/ai/Seedance.php';
  // Music AI (updated URL)
  static const String _musicAiUrl     = 'https://viscodev.x10.mx/musicai/api.php';
  // Veo 3 Video AI (NEW — 2 steps: create task + poll result)
  static const String _veoCreateUrl   = 'https://vetrex.site/v1/videos/generations';
  static const String _veoResultUrl   = 'https://vetrex.site/v1/videos/results';

  // Public getters
  static String get geminiUrl      => _geminiUrl;
  static String get gptImg2Url     => _gptImg2Url;
  static String get imageNanoUrl   => _imageNanoUrl;
  static String get kilwaVideoUrl  => _kilwaVideoUrl;
  static String get deepSeekUrl    => _deepSeekUrl;
  static String get nanoBanaProUrl => _nanoBanaProUrl;
  static String get seedanceUrl    => _seedanceUrl;
  static String get musicAiUrl     => _musicAiUrl;
  static String get veoCreateUrl   => _veoCreateUrl;
  static String get veoResultUrl   => _veoResultUrl;

  // ── Firestore Collections ─────────────────────────────────────────────
  static const String colUsers      = 'users';
  static const String colChats      = 'chats';
  static const String colGroups     = 'groups';
  static const String colStories    = 'stories';
  static const String colSupport    = 'support';
  static const String colBroadcast  = 'broadcasts';
  static const String colAiLogs     = 'ai_logs';
  static const String colStickers   = 'stickers';
  static const String colNotifs     = 'notifications';
  static const String colPolls      = 'polls';
  static const String colReports    = 'reports';

  // ── Story limits ──────────────────────────────────────────────────────
  static const int storyDurationHours   = 48;
  static const int maxStoriesPerCycle   = 3;
  static const int maxStoryVideoSeconds = 300;

  // ── Message limits ────────────────────────────────────────────────────
  static const int maxMessageLength   = 5000;
  static const int maxStickerVideoSec = 15;
  static const int maxStickersPerPack = 250;

  // ── Validation ────────────────────────────────────────────────────────
  static const int minUsernameLen    = 4;
  static const int maxUsernameLen    = 25;
  static const int minPasswordLen    = 4;
  static const int maxPasswordLen    = 100;
  static const int maxNameLen        = 50;
  static const String usernamePattern = r'^[a-zA-Z0-9_-]+$';
  static const int userIdLength      = 15;

  // ── Seedance Models ───────────────────────────────────────────────────
  static const List<Map<String, dynamic>> seedanceModels = [
    {
      'id': 'Seedance 1.5 Pro',
      'name': 'Seedance 1.5 Pro',
      'durations': [4, 8, 12],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
    {
      'id': 'Seedance 1.0 Pro',
      'name': 'Seedance 1.0 Pro',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
    {
      'id': 'Seedance 1.0 Lite',
      'name': 'Seedance 1.0 Lite',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImage': true,
    },
  ];

  // ── Image generation ──────────────────────────────────────────────────
  static const List<String> imageRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const List<String> imageResolutions = ['1K', '2K', '4K'];

  // ── Veo 3 models ─────────────────────────────────────────────────────
  static const List<String> veoModels = ['veo-3.1', 'veo-2'];
  static const List<String> veoRatios = ['16:9', '9:16'];

  // ── DeepSeek models ───────────────────────────────────────────────────
  static const Map<String, String> deepSeekModels = {
    '1': 'DeepSeek V3.2',
    '2': 'DeepSeek R1',
    '3': 'DeepSeek Coder',
  };

  // ── Music tags ────────────────────────────────────────────────────────
  static const List<String> musicTags = ['sad', 'happy', 'romantic', 'energetic'];

  // ── AI service keys for admin panel ──────────────────────────────────
  static const List<String> aiServiceKeys = [
    'gemini', 'deepseek', 'imageGen', 'gptImg2',
    'nanoBananaPro', 'seedance', 'veoVideo', 'kilwaVideo', 'musicAi',
  ];
  static const Map<String, String> aiServiceNames = {
    'gemini':        'Gemini 2.5 Flash',
    'deepseek':      'DeepSeek AI',
    'imageGen':      'Nano Banana 2',
    'gptImg2':       'GPT Image 2 ✨',
    'nanoBananaPro': 'NanoBanana Pro',
    'seedance':      'Seedance Video AI',
    'veoVideo':      'Veo 3 Video AI ✨',
    'kilwaVideo':    'Kilwa Video',
    'musicAi':       'AI Music Generator',
  };

  // ── Reaction emojis ───────────────────────────────────────────────────
  static const List<String> reactions = [
    '❤️','😂','😢','👍','😱','🔥','🤔','👏',
    '🙏','💕','💔','😍','🤣','😭','🤩','😡',
    '😈','💯','✅','❌','🎉','🏆','⭐','💫',
  ];

  // ── Voice message ─────────────────────────────────────────────────────
  static const int maxVoiceSeconds = 300; // 5 minutes

  // ── Chat background presets ───────────────────────────────────────────
  static const List<Map<String, dynamic>> chatBackgrounds = [
    {'id': 'none', 'label': 'بلا خلفية', 'color': null, 'url': null},
    {'id': 'dark_stars', 'label': 'نجوم', 'gradient': [0xFF0D0D1A, 0xFF1A0020]},
    {'id': 'deep_red', 'label': 'أحمر عميق', 'gradient': [0xFF1A0008, 0xFF0D0005]},
    {'id': 'midnight', 'label': 'منتصف الليل', 'gradient': [0xFF0A0A14, 0xFF14141E]},
    {'id': 'forest', 'label': 'غابة', 'gradient': [0xFF0A1A0A, 0xFF0D200D]},
    {'id': 'ocean', 'label': 'محيط', 'gradient': [0xFF0A0A1A, 0xFF0D1A2A]},
    {'id': 'sunset', 'label': 'غروب', 'gradient': [0xFF1A0A05, 0xFF201020]},
  ];

  // ── Avatar colors ─────────────────────────────────────────────────────
  static const List<int> avatarColors = [
    0xFF8B0000, 0xFF1565C0, 0xFF2E7D32, 0xFF6A1B9A,
    0xFF00838F, 0xFFEF6C00, 0xFFAD1457, 0xFF37474F,
    0xFF4E342E, 0xFF004D40, 0xFF1B5E20, 0xFF1A237E,
  ];

  // ── SharedPreferences keys ────────────────────────────────────────────
  static const String prefLanguage    = 'lang';
  static const String prefTheme       = 'theme';
  static const String prefCurrentUser = 'cur_user';
  static const String prefAccounts    = 'accounts';
  static const String prefChatBg      = 'chat_bg';
  static const String prefAccentColor = 'accentColor';
  static const String prefFontScale   = 'fontScale';
  static const String prefBiometric   = 'biometric';
  static const String prefAutoNight   = 'autoNight';

  AppConstants._();
}
