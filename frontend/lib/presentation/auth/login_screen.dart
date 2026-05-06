import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _obscure   = true;
  bool _submitted = false;

  late AnimationController _fadeCtrl;
  late AnimationController _floatCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _floatAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _floatCtrl.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    final err = await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8), Expanded(child: Text(err)),
        ]),
        backgroundColor: AppColors.red,
      ));
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ─────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF581C87), Color(0xFF1D4ED8)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // ── Floating orbs for depth ─────────────────────────────────────
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Stack(children: [
              Positioned(top: 60 + _floatAnim.value, left: -60,
                child: _orb(200, const Color(0xFF3B82F6), 0.3)),
              Positioned(bottom: 80 - _floatAnim.value, right: -40,
                child: _orb(160, const Color(0xFF8B5CF6), 0.25)),
              Positioned(top: 200 - _floatAnim.value * 0.5, right: 20,
                child: _orb(100, const Color(0xFF06B6D4), 0.2)),
            ]),
          ),
          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(children: [
                        // Logo
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _floatAnim.value * 0.5),
                            child: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Cipher', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                        const SizedBox(height: 4),
                        Text('Task Management Platform', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(height: 32),

                        // ── Glassmorphic card ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 16)),
                              BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Welcome back', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                            const SizedBox(height: 4),
                            Text('Sign in to your workspace', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 24),
                            Form(
                              key: _form,
                              autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                _glassLabel('Email address'),
                                _GlassField(
                                  controller: _email,
                                  hint: 'you@example.com',
                                  icon: Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                  action: TextInputAction.next,
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                _glassLabel('Password'),
                                _GlassField(
                                  controller: _pass,
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure,
                                  action: TextInputAction.done,
                                  onSubmit: (_) => _submit(),
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white.withValues(alpha: 0.7), size: 20),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                // Submit button
                                GestureDetector(
                                  onTap: loading ? null : _submit,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
                                    ),
                                    child: Center(
                                      child: loading
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                                            ]),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 18),

                        // Register link
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                          child: RichText(text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(text: 'Create one', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: Colors.white)),
                            ],
                          )),
                        ),
                        const SizedBox(height: 12),

                        // Demo credentials
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text('Demo Accounts — tap to fill', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                            ]),
                            const SizedBox(height: 8),
                            _demoRow('Admin',   'admin@cipher.ai',   'Admin123'),
                            _demoRow('Manager', 'manager@cipher.ai', 'Manager1'),
                            _demoRow('Member',  'member@cipher.ai',  'Member123'),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
    ),
  );

  Widget _glassLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
  );

  Widget _demoRow(String role, String email, String pass) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: GestureDetector(
      onTap: () { _email.text = email; _pass.text = pass; },
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(role, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Text('$email / $pass', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ]),
    ),
  );
}

// ── Glass input field ─────────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? type;
  final TextInputAction? action;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmit;
  final Widget? suffixIcon;

  const _GlassField({
    required this.controller, required this.hint, required this.icon,
    this.obscure = false, this.type, this.action, this.validator, this.onSubmit, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: type,
    textInputAction: action,
    onFieldSubmitted: onSubmit,
    validator: validator,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
      errorStyle: GoogleFonts.inter(color: Colors.red.shade200, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
