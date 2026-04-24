import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeathon/core/app_theme.dart';
import 'package:codeathon/screens/role_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RoleSelectScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.kHeroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing logo
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.kPrimaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kPrimary.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 52),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    curve: Curves.elasticOut,
                    duration: 900.ms,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 28),

              Text(
                'GTC 2026 (1.2)',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.kTextPrimary,
                  letterSpacing: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.4),

              const SizedBox(height: 8),
              Text(
                'Team Tracking System',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.kTextSecondary,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms),

              const SizedBox(height: 60),

              // Loading dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.kPrimary,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                        onPlay: (c) => c.repeat(),
                        delay: Duration(milliseconds: 1200 + i * 150),
                      )
                      .scaleXY(
                        begin: 0.5,
                        end: 1.3,
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scaleXY(
                        begin: 1.3,
                        end: 0.5,
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
