import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class AiServicesTab extends StatelessWidget {
  const AiServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
      children: [
        _SectionHeader(title: '💬 دردشة ذكية'),
        _ServiceCard(
          title: 'Gemini 2.5 Flash',
          subtitle: 'أذكى نماذج Google - ردود فورية',
          icon: Icons.auto_awesome_rounded,
          gradient: const [Color(0xFF4285F4), Color(0xFF1A73E8)],
          badge: 'Google AI',
          route: AppRoutes.geminiChat,
        ),
        _ServiceCard(
          title: 'DeepSeek Pro',
          subtitle: 'V3.2 | R1 | Coder - ذاكرة محادثة',
          icon: Icons.psychology_rounded,
          gradient: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
          badge: 'DeepSeek AI',
          route: AppRoutes.deepSeekChat,
        ),
        const SizedBox(height: 12),
        _SectionHeader(title: '🖼️ توليد صور'),
        _ServiceCard(
          title: 'GPT Image 2',
          subtitle: 'توليد صور احترافية بجودة عالية',
          icon: Icons.image_rounded,
          gradient: const [Color(0xFF10A37F), Color(0xFF1A7A5E)],
          badge: '✨ NEW',
          route: AppRoutes.imageGen,
        ),
        _ServiceCard(
          title: 'NanoBanana Pro',
          subtitle: 'إنشاء وتعديل صور - جودة 4K',
          icon: Icons.auto_fix_high_rounded,
          gradient: const [Color(0xFFFF6B35), Color(0xFFE91E63)],
          badge: 'Pro',
          route: AppRoutes.imageGenPro,
        ),
        const SizedBox(height: 12),
        _SectionHeader(title: '🎬 توليد فيديو'),
        _ServiceCard(
          title: 'Veo 3 Video AI',
          subtitle: 'فيديو سينمائي بصوت حقيقي 16:9 / 9:16',
          icon: Icons.movie_creation_rounded,
          gradient: const [Color(0xFF7B1FA2), Color(0xFF4A148C)],
          badge: '✨ NEW',
          route: AppRoutes.videoGen,
        ),
        _ServiceCard(
          title: 'Seedance AI',
          subtitle: 'صورة إلى فيديو - 4/8/12 ثانية',
          icon: Icons.videocam_rounded,
          gradient: const [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
          badge: '1.5 Pro',
          route: AppRoutes.videoGen,
        ),
        const SizedBox(height: 12),
        _SectionHeader(title: '🎵 موسيقى وصوت'),
        _ServiceCard(
          title: 'AI Music Generator',
          subtitle: 'توليد موسيقى بالذكاء الاصطناعي - حزين، سعيد، رومانسي',
          icon: Icons.music_note_rounded,
          gradient: const [Color(0xFFAD1457), Color(0xFF880E4F)],
          badge: 'Visco AI',
          route: AppRoutes.musicAi,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(title, style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    )),
  );
}

class _ServiceCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String badge;
  final String route;
  const _ServiceCard({
    required this.title, required this.subtitle, required this.icon,
    required this.gradient, required this.badge, required this.route,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient[0].withOpacity(0.15), gradient[1].withOpacity(0.08)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gradient[0].withOpacity(0.3), width: 0.8),
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 10, offset: const Offset(0,3))],
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gradient[0].withOpacity(0.7)),
      ]),
    ),
  );
}
