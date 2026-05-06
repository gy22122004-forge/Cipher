import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _conf  = TextEditingController();
  bool _obscure    = true;
  bool _obscureConf = true;
  bool _submitted  = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _name.dispose(); _email.dispose(); _pass.dispose(); _conf.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 60) return 'Name is too long';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Password must contain a digit';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    if (_pass.text != _conf.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: AppColors.red,
      ));
      return;
    }
    final err = await ref.read(authProvider.notifier).register(
      _name.text.trim(), _email.text.trim(), _pass.text,
    );
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(err)),
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Cipher', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.5)),
                          Text('Task Management', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)),
                        ]),
                      ]),
                      const SizedBox(height: 36),
                      Text('Create account', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.6)),
                      const SizedBox(height: 6),
                      Text('Join your team on Cipher', style: GoogleFonts.inter(fontSize: 14, color: AppColors.text3)),
                      const SizedBox(height: 28),

                      // Password strength hint
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.amber),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Password must be 6+ characters with at least one uppercase letter and one digit.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.amber, height: 1.5))),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Form(
                          key: _form,
                          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const FieldLabel(text: 'Full Name', required: true),
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(hintText: 'John Doe', prefixIcon: Icon(Icons.person_outline, size: 20)),
                                validator: _validateName,
                              ),
                              const SizedBox(height: 14),
                              const FieldLabel(text: 'Email Address', required: true),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 14),
                              const FieldLabel(text: 'Password', required: true),
                              TextFormField(
                                controller: _pass,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'Min 6 chars, uppercase + digit',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 14),
                              const FieldLabel(text: 'Confirm Password', required: true),
                              TextFormField(
                                controller: _conf,
                                obscureText: _obscureConf,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'Re-enter password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                    onPressed: () => setState(() => _obscureConf = !_obscureConf),
                                  ),
                                ),
                                validator: (v) => v != _pass.text ? 'Passwords do not match' : null,
                              ),
                              const SizedBox(height: 24),
                              LoadingButton(
                                loading: loading,
                                onPressed: _submit,
                                label: 'Create Account',
                                icon: Icons.person_add_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text3),
                              children: [
                                const TextSpan(text: 'Already have an account? '),
                                TextSpan(text: 'Sign In', style: GoogleFonts.inter(color: AppColors.blue, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: AppColors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
