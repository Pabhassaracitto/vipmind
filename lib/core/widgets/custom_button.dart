import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.width,
    this.height = 54,
    this.borderRadius = 12,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? _onTapDown : null,
      onTapUp: isEnabled ? _onTapUp : null,
      onTapCancel: isEnabled ? _onTapCancel : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(isEnabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool isEnabled) {
    if (widget.isOutlined) {
      return _buildOutlinedButton(isEnabled);
    }
    return _buildFilledButton(isEnabled);
  }

  Widget _buildFilledButton(bool isEnabled) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? (widget.gradient ?? AppColors.primaryGradient)
            : null,
        color: isEnabled
            ? null
            : (widget.backgroundColor ?? AppColors.primaryBlue).withOpacity(0.5),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: isEnabled
            ? [
          BoxShadow(
            color: (widget.backgroundColor ?? AppColors.primaryBlue)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: _buildContent(isEnabled, Colors.white),
    );
  }

  Widget _buildOutlinedButton(bool isEnabled) {
    final color = widget.backgroundColor ?? AppColors.primaryBlue;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isEnabled ? color : color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: _buildContent(
        isEnabled,
        isEnabled ? color : color.withOpacity(0.5),
      ),
    );
  }

  Widget _buildContent(bool isEnabled, Color contentColor) {
    return Center(
      child: widget.isLoading
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: widget.textColor ?? contentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor ?? contentColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}