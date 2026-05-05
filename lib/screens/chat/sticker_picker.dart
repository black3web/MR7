import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';

// Built-in sticker packs (emoji + common stickers)
class StickerPicker extends StatefulWidget {
  final Function(String url) onStickerSelected;
  final VoidCallback onClose;
  const StickerPicker({super.key, required this.onStickerSelected, required this.onClose});
  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _packIdx = 0;

  // Built-in emoji packs
  static const List<Map<String, dynamic>> _packs = [
    {
      'name': '😀 تعابير',
      'icon': '😀',
      'stickers': [
        '😀','😂','🤣','😊','🥰','😍','🤩','😎',
        '😢','😭','😤','😡','🤯','😱','🥳','🎉',
        '👍','👎','❤️','💔','🔥','💯','✅','❌',
        '🙏','👏','🫡','💪','🤝','🫶','💕','😘',
      ],
    },
    {
      'name': '🐾 حيوانات',
      'icon': '🐾',
      'stickers': [
        '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼',
        '🐨','🐯','🦁','🐮','🐷','🐸','🐵','🐔',
        '🦋','🐝','🦄','🐲','🦅','🦜','🐬','🐋',
        '🦁','🦊','🐺','🦝','🦔','🦦','🦥','🐧',
      ],
    },
    {
      'name': '🍕 طعام',
      'icon': '🍕',
      'stickers': [
        '🍕','🍔','🌮','🌯','🍜','🍣','🍱','🧆',
        '🍩','🎂','🍰','🍪','🍫','🍭','🍦','🧁',
        '☕','🧋','🥤','🍵','🍺','🥛','🧃','🍶',
        '🍎','🍊','🍋','🍇','🍓','🥑','🌽','🥕',
      ],
    },
    {
      'name': '🌍 سفر',
      'icon': '🌍',
      'stickers': [
        '✈️','🚀','🛸','🌍','🌎','🌏','🗺️','🏝',
        '🏔','🌋','🏕','🏜','🌊','🌺','🌴','🌵',
        '🎡','🎢','🎠','🏟','🗽','🗼','🏯','🕌',
        '⛺','🏠','🏰','🌃','🌆','🌇','🌉','🌠',
      ],
    },
    {
      'name': '⚡ رموز',
      'icon': '⚡',
      'stickers': [
        '⚡','🔥','💫','✨','🌟','⭐','🎯','🏆',
        '🎮','💎','👑','🔮','🌈','💠','🔑','🗝',
        '💡','🔔','📱','💻','🎵','🎶','🎸','🎹',
        '🎃','🎄','🎆','🎇','🧨','🎊','🎋','🎍',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _packs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() => _packIdx = _tabCtrl.index));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    height: 300,
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      border: Border(top: BorderSide(color: AppColors.glassBorder)),
    ),
    child: Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        child: Row(children: [
          const Text('الملصقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const Spacer(),
          GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20)),
        ]),
      ),

      // Pack tabs
      SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _packs.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () { _tabCtrl.animateTo(i); setState(() => _packIdx = i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: _packIdx == i ? AppGradients.accentGradient : null,
                color: _packIdx == i ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _packIdx == i ? AppColors.accent : AppColors.glassBorder),
              ),
              child: Text(_packs[i]['icon'] as String,
                  style: TextStyle(fontSize: _packIdx == i ? 18 : 16)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Stickers grid
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: _packs.map((pack) {
            final stickers = pack['stickers'] as List<String>;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8, mainAxisSpacing: 2, crossAxisSpacing: 2),
              itemCount: stickers.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => widget.onStickerSelected(_emojiToDataUrl(stickers[i])),
                child: Center(
                  child: Text(stickers[i], style: const TextStyle(fontSize: 28)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ]),
  );

  // Convert emoji to a "url" that we handle specially
  // In real app you'd have actual sticker image URLs
  String _emojiToDataUrl(String emoji) => 'emoji:$emoji';
}
