import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _QuickActionCard(
            icon: Icons.psychology_rounded,
            label: 'Brain Dump',
            color: AppColors.creativePurple,
            onTap: () => Navigator.pushNamed(context, AppRoutes.textToMindmap),
          ),
          _QuickActionCard(
            icon: Icons.mic_rounded,
            label: 'Voice Note',
            color: AppColors.accentYellow,
            onTap: () => Navigator.pushNamed(context, AppRoutes.voiceToMindmap),
          ),
          _QuickActionCard(
            icon: Icons.spa_rounded,
            label: 'Zen Mode',
            color: AppColors.calmGreen,
            onTap: () => Navigator.pushNamed(context, AppRoutes.zenMode),
          ),
          _QuickActionCard(
            icon: Icons.style_rounded,
            label: 'Flashcards',
            color: AppColors.primaryBlue,
            onTap: () => Navigator.pushNamed(context, AppRoutes.ankiDeck),
          ),
          _QuickActionCard(
            icon: Icons.dashboard_customize,
            label: 'Templates',
            color: AppColors.warningOrange,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.templateGallery),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
