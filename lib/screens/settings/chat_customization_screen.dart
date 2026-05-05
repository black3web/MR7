import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../services/customization_service.dart';

/// شاشة تخصيص المحادثة - الخلفيات، الألوان، الخطوط
class ChatCustomizationScreen extends StatefulWidget {
  final String userId;
  final String chatId;
  final String chatName;

  const ChatCustomizationScreen({
    super.key,
    required this.userId,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatCustomizationScreen> createState() => _ChatCustomizationScreenState();
}

class _ChatCustomizationScreenState extends State<ChatCustomizationScreen> {
  final CustomizationService _customization = CustomizationService();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _currentBackground;
  Color _accentColor = const Color(0xFFB22222);
  String _bubbleStyle = 'glass';
  double _fontScale = 1.0;
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bg = await _customization.getChatBackground(
      userId: widget.userId,
      chatId: widget.chatId,
    );
    final color = await _customization.getAccentColor(widget.userId);
    final style = await _customization.getBubbleStyle(widget.userId);
    final scale = await _customization.getFontScale(widget.userId);
    final animations = await _customization.getAnimationsEnabled(widget.userId);

    setState(() {
      _currentBackground = bg;
      _accentColor = color;
      _bubbleStyle = style;
      _fontScale = scale;
      _animationsEnabled = animations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('تخصيص ${widget.chatName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaults,
            tooltip: 'استعادة الإعدادات الافتراضية',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildBackgroundSection(),
          const Divider(height: 1),
          _buildColorSection(),
          const Divider(height: 1),
          _buildBubbleStyleSection(),
          const Divider(height: 1),
          _buildFontSection(),
          const Divider(height: 1),
          _buildAnimationsSection(),
          const Divider(height: 1),
          _buildNotificationSection(),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'خلفية المحادثة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        
        // معاينة الخلفية الحالية
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            gradient: _getBackgroundGradient(),
            image: _currentBackground?['type'] == 'image'
                ? DecorationImage(
                    image: FileImage(File(_currentBackground!['data'])),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                'معاينة الرسالة',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // الخلفيات الجاهزة
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: AppConstants.chatBackgrounds.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCustomImageOption();
              }
              final bg = AppConstants.chatBackgrounds[index - 1];
              return _buildPresetOption(bg);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomImageOption() {
    return GestureDetector(
      onTap: _pickCustomImage,
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent, width: 2),
        ),
        child: Icon(Icons.add_photo_alternate, color: AppColors.accent),
      ),
    );
  }

  Widget _buildPresetOption(Map<String, dynamic> bg) {
    final isSelected = _currentBackground?['type'] == 'preset' && 
                       _currentBackground?['data']['id'] == bg['id'];

    return GestureDetector(
      onTap: () => _applyPreset(bg),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: bg['gradient'] != null
              ? LinearGradient(
                  colors: (bg['gradient'] as List).map((c) => Color(c)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: bg['color'] != null ? Color(bg['color']) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.1),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildColorSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لون التطبيق الأساسي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Color(0xFFB22222), // Dark Red
              const Color(0xFF1565C0), // Blue
              const Color(0xFF2E7D32), // Green
              const Color(0xFF6A1B9A), // Purple
              const Color(0xFFEF6C00), // Orange
              const Color(0xFF00838F), // Cyan
              const Color(0xFFAD1457), // Pink
              const Color(0xFF37474F), // Grey
            ].map((color) {
              final isSelected = _accentColor.value == color.value;
              return GestureDetector(
                onTap: () => _changeAccentColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleStyleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمط فقاعات الرسائل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStyleOption('glass', 'زجاجي', Icons.blur_on),
              _buildStyleOption('modern', 'حديث', Icons.rounded_corner),
              _buildStyleOption('classic', 'كلاسيكي', Icons.chat_bubble),
              _buildStyleOption('minimal', 'بسيط', Icons.rectangle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleOption(String style, String label, IconData icon) {
    final isSelected = _bubbleStyle == style;
    return GestureDetector(
      onTap: () => _changeBubbleStyle(style),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حجم الخط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.text_fields, color: AppColors.textSecondary, size: 16),
              Expanded(
                child: Slider(
                  value: _fontScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  label: '${(_fontScale * 100).toInt()}%',
                  activeColor: AppColors.accent,
                  onChanged: (value) {
                    setState(() => _fontScale = value);
                  },
                  onChangeEnd: (value) async {
                    await _customization.setFontScale(
                      userId: widget.userId,
                      scale: value,
                    );
                  },
                ),
              ),
              Icon(Icons.text_fields, color: AppColors.textSecondary, size: 24),
            ],
          ),
          Center(
            child: Text(
              'مثال على النص بالحجم الحالي',
              style: TextStyle(
                fontSize: 15 * _fontScale,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationsSection() {
    return SwitchListTile(
      title: Text('الرسوم المتحركة', style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        'تأثيرات الحركة عند إرسال واستقبال الرسائل',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      value: _animationsEnabled,
      activeColor: AppColors.accent,
      onChanged: (value) async {
        setState(() => _animationsEnabled = value);
        await _customization.setAnimationsEnabled(
          userId: widget.userId,
          enabled: value,
        );
      },
    );
  }

  Widget _buildNotificationSection() {
    return ListTile(
      leading: Icon(Icons.notifications, color: AppColors.accent),
      title: Text('إعدادات الإشعارات', style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text('صوت مخصص، اهتزاز، LED', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to notification settings
      },
    );
  }

  LinearGradient? _getBackgroundGradient() {
    if (_currentBackground?['type'] != 'preset') return null;
    final gradient = _currentBackground?['data']['gradient'];
    if (gradient == null) return null;
    
    return LinearGradient(
      colors: (gradient as List).map((c) => Color(c)).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Future<void> _pickCustomImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    await _customization.setCustomBackground(
      userId: widget.userId,
      chatId: widget.chatId,
      imageFile: File(image.path),
    );

    setState(() {
      _currentBackground = {'type': 'image', 'data': image.path};
    });

    _showSnackBar('تم تعيين الخلفية المخصصة');
  }

  Future<void> _applyPreset(Map<String, dynamic> bg) async {
    await _customization.setPresetBackground(
      userId: widget.userId,
      chatId: widget.chatId,
      presetId: bg['id'],
    );

    setState(() {
      _currentBackground = {'type': 'preset', 'data': bg};
    });

    _showSnackBar('تم تطبيق الخلفية');
  }

  Future<void> _changeAccentColor(Color color) async {
    await _customization.setAccentColor(
      userId: widget.userId,
      color: color,
    );

    setState(() => _accentColor = color);
    _showSnackBar('تم تغيير اللون الأساسي');
  }

  Future<void> _changeBubbleStyle(String style) async {
    await _customization.setBubbleStyle(
      userId: widget.userId,
      style: style,
    );

    setState(() => _bubbleStyle = style);
    _showSnackBar('تم تغيير نمط الفقاعات');
  }

  Future<void> _resetToDefaults() async {
    await _customization.clearChatBackground(
      userId: widget.userId,
      chatId: widget.chatId,
    );

    setState(() {
      _currentBackground = null;
      _accentColor = const Color(0xFFB22222);
      _bubbleStyle = 'glass';
      _fontScale = 1.0;
      _animationsEnabled = true;
    });

    _showSnackBar('تم استعادة الإعدادات الافتراضية');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
