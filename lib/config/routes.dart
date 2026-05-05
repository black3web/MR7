import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/language_select_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/group_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/stories/story_view_screen.dart';
import '../screens/stories/add_story_screen.dart';
import '../screens/ai/gemini_chat_screen.dart';
import '../screens/ai/deepseek_chat_screen.dart';
import '../screens/ai/image_gen_screen.dart';
import '../screens/ai/video_gen_screen.dart';
import '../screens/ai/music_ai_screen.dart';
import '../screens/ai/kilwa_video_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../models/story_model.dart';

class AppRoutes {
  static const String splash         = '/';
  static const String language       = '/language';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String home           = '/home';
  static const String chat           = '/chat';
  static const String groupChat      = '/group-chat';
  static const String profile        = '/profile';
  static const String editProfile    = '/edit-profile';
  static const String userProfile    = '/user-profile';
  static const String storyView      = '/story-view';
  static const String addStory       = '/add-story';
  static const String geminiChat     = '/ai/gemini';
  static const String deepSeekChat   = '/ai/deepseek';
  static const String imageGen       = '/ai/image-gen';
  static const String imageGenPro    = '/ai/image-gen-pro';
  static const String videoGen       = '/ai/video-gen';
  static const String musicAi        = '/ai/music';
  static const String kilwaVideo     = '/ai/kilwa-video';
  static const String settings       = '/settings';
  static const String support        = '/support';
  static const String admin          = '/admin';
  static const String search         = '/search';
  static const String notifications  = '/notifications';
  static const String imageView      = '/imageView';

  static Map<String, WidgetBuilder> get routes => {
    splash:         (_) => const SplashScreen(),
    language:       (_) => const LanguageSelectScreen(),
    login:          (_) => const LoginScreen(),
    register:       (_) => const RegisterScreen(),
    home:           (_) => const HomeScreen(),
    profile:        (_) => const ProfileScreen(),
    editProfile:    (_) => const EditProfileScreen(),
    settings:       (_) => const SettingsScreen(),
    support:        (_) => const SupportScreen(),
    admin:          (_) => const AdminScreen(),
    search:         (_) => const SearchScreen(),
    notifications:  (_) => const NotificationsScreen(),
    geminiChat:     (_) => const GeminiChatScreen(),
    deepSeekChat:   (_) => const DeepSeekChatScreen(),
    imageGen:       (_) => const ImageGenScreen(),
    imageGenPro:    (_) => const ImageGenScreen(),
    videoGen:       (_) => const VideoGenScreen(),
    musicAi:        (_) => const MusicAiScreen(),
    kilwaVideo:     (_) => const KilwaVideoScreen(),
    addStory:       (_) => const AddStoryScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings s) {
    switch (s.name) {
      case chat:
        final a = s.arguments as Map<String, dynamic>;
        return _slide(ChatScreen(chatId: a['chatId'], otherUserId: a['otherUserId']));
      case groupChat:
        final a = s.arguments as Map<String, dynamic>;
        return _slide(GroupChatScreen(groupId: a['groupId']));
      case userProfile:
        final a = s.arguments as Map<String, dynamic>;
        return _slide(UserProfileScreen(userId: a['userId']));
      case storyView:
        final a = s.arguments as Map<String, dynamic>;
        return _fade(StoryViewScreen(
          stories: (a['stories'] as List).cast<StoryModel>(),
          initialIndex: (a['initialIndex'] as int?) ?? 0,
        ));
      case imageView:
        final a = s.arguments as Map<String, dynamic>;
        return _fade(_FullImageScreen(url: a['url'] as String));
      default:
        return _slide(const SplashScreen());
    }
  }

  static PageRouteBuilder<T> _slide<T>(Widget child) => PageRouteBuilder<T>(
    pageBuilder: (_, a, __) => child,
    transitionsBuilder: (_, a, __, c) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: c),
    ),
    transitionDuration: const Duration(milliseconds: 240),
  );

  static PageRouteBuilder<T> _fade<T>(Widget child) => PageRouteBuilder<T>(
    pageBuilder: (_, a, __) => child,
    transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: c),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

// ─── Full screen image viewer ────────────────────────────────────────────────
class _FullImageScreen extends StatelessWidget {
  final String url;
  const _FullImageScreen({required this.url});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
    body: Center(child: InteractiveViewer(
      minScale: 0.5, maxScale: 5,
      child: Image.network(url, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 56)),
    )),
  );
}
