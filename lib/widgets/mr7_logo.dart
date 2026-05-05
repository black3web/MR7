import 'package:flutter/material.dart';
import '../config/theme.dart';

class MR7Logo extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  const MR7Logo({super.key, this.fontSize = 24, this.showSubtitle = false});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ShaderMask(
        shaderCallback: (b) => AppGradients.accentGradient.createShader(b),
        child: Text(
          'MR7',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      if (showSubtitle)
        Text(
          'CHAT',
          style: TextStyle(
            fontSize: fontSize * 0.38,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 5,
          ),
        ),
    ],
  );
}
