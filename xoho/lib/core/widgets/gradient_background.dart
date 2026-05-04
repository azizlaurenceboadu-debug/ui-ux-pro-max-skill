import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class XohoBackground extends StatelessWidget {
  const XohoBackground({
    super.key,
    required this.child,
    this.showGlowTop = true,
    this.showGlowBottom = false,
  });

  final Widget child;
  final bool showGlowTop;
  final bool showGlowBottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        ),
        if (showGlowTop)
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(
              size: 260,
              color: AppColors.primary.withOpacity(0.12),
            ),
          ),
        if (showGlowBottom)
          Positioned(
            bottom: 60,
            left: -80,
            child: _GlowBlob(
              size: 200,
              color: AppColors.info.withOpacity(0.06),
            ),
          ),
        child,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

class AnimatedGlowBackground extends StatefulWidget {
  const AnimatedGlowBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedGlowBackground> createState() => _AnimatedGlowBackgroundState();
}

class _AnimatedGlowBackgroundState extends State<AnimatedGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppColors.bgGradient),
            ),
            Positioned(
              top: -60 + (_anim.value * 30),
              right: -40 + (_anim.value * 20),
              child: _GlowBlob(
                size: 280,
                color: AppColors.primary.withOpacity(0.10 + _anim.value * 0.04),
              ),
            ),
            Positioned(
              top: 200 - (_anim.value * 20),
              left: -80,
              child: _GlowBlob(
                size: 200,
                color: AppColors.info.withOpacity(0.05),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
