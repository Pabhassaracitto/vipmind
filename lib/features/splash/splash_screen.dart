import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              Color(0xFF1a2a4a),
              AppColors.primaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildLogo(),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Name
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: const Text(
                    'NeuroMindmap',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: AnimatedBuilder(
                    animation: _opacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnimation.value,
                        child: const Text(
                          'Your Brain, Amplified.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLightSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 80),

                // Loading indicator
                FadeIn(
                  delay: const Duration(milliseconds: 1200),
                  child: const _NeuralLoadingIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.creativePurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology_rounded,
        size: 60,
        color: Colors.white,
      ),
    );
  }
}

class _NeuralLoadingIndicator extends StatefulWidget {
  const _NeuralLoadingIndicator();

  @override
  State<_NeuralLoadingIndicator> createState() => _NeuralLoadingIndicatorState();
}

class _NeuralLoadingIndicatorState extends State<_NeuralLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value + delay) % 1.0;
              final scale = 0.5 + (value < 0.5 ? value : 1 - value);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12 * scale,
                height: 12 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.5 + scale * 0.5),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}