import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum XohoButtonVariant { primary, secondary, ghost, danger }

enum XohoButtonSize { large, medium, small }

class XohoButton extends StatefulWidget {
  const XohoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = XohoButtonVariant.primary,
    this.size = XohoButtonSize.large,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final XohoButtonVariant variant;
  final XohoButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<XohoButton> createState() => _XohoButtonState();
}

class _XohoButtonState extends State<XohoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null || widget.isLoading) return;
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final double height = switch (widget.size) {
      XohoButtonSize.large => 56,
      XohoButtonSize.medium => 48,
      XohoButtonSize.small => 40,
    };

    final TextStyle labelStyle = switch (widget.size) {
      XohoButtonSize.large => AppTextStyles.button,
      XohoButtonSize.medium => AppTextStyles.button.copyWith(fontSize: 15),
      XohoButtonSize.small => AppTextStyles.buttonSM,
    };

    final (bgColor, fgColor, borderColor) = switch (widget.variant) {
      XohoButtonVariant.primary => (
          AppColors.primary,
          AppColors.textOnPrimary,
          Colors.transparent,
        ),
      XohoButtonVariant.secondary => (
          AppColors.glassOrange,
          AppColors.primary,
          AppColors.primary.withOpacity(0.3),
        ),
      XohoButtonVariant.ghost => (
          Colors.transparent,
          AppColors.textSecondary,
          AppColors.border,
        ),
      XohoButtonVariant.danger => (
          AppColors.errorBg,
          AppColors.error,
          AppColors.error.withOpacity(0.3),
        ),
    };

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: (widget.onPressed != null && !widget.isLoading)
          ? widget.onPressed
          : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          width: widget.fullWidth ? double.infinity : null,
          padding: widget.fullWidth
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: widget.variant == XohoButtonVariant.primary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        IconTheme(
                          data: IconThemeData(color: fgColor, size: 20),
                          child: widget.icon!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: labelStyle.copyWith(color: fgColor),
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        IconTheme(
                          data: IconThemeData(color: fgColor, size: 20),
                          child: widget.trailingIcon!,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
