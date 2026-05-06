import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double>  _logoScale;
  late Animation<double>  _logoOpacity;
  late Animation<Offset>  _textSlide;
  late Animation<double>  _textOpacity;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _logoScale   = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));
    _textSlide   = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _logoCtrl.forward().then((_) => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final auth = ref.read(authProvider);
    Navigator.of(context).pushReplacementNamed(auth.isAuthenticated ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.loading == true && !next.loading) _navigate();
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Subtle background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
                          BoxShadow(color: AppColors.blue.withValues(alpha: 0.12), blurRadius: 48, offset: const Offset(0, 16)),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Animated text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(children: [
                      Text('Cipher',
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1.0)),
                      const SizedBox(height: 4),
                      Text('Task Management Platform',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.text3, fontWeight: FontWeight.w500, letterSpacing: 0.1)),
                    ]),
                  ),
                ),
                const SizedBox(height: 64),
                // Loading indicator
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Version tag at bottom
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text('v1.0.0 · Cipher A1 Campus Drive',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.text4, letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
