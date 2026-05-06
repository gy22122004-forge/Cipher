import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.blue)));
    }

    final roleColor = switch (user.role) {
      'admin'   => AppColors.red,
      'manager' => AppColors.blue,
      _         => AppColors.green,
    };
    final roleBg = switch (user.role) {
      'admin'   => AppColors.redLight,
      'manager' => AppColors.blueLight,
      _         => AppColors.greenLight,
    };
    final roleIcon = switch (user.role) {
      'admin'   => Icons.admin_panel_settings_rounded,
      'manager' => Icons.manage_accounts_rounded,
      _         => Icons.person_rounded,
    };
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero header ─────────────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(children: [
              // Avatar with ring
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.2), width: 3),
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.blueLight,
                  child: Text(initial,
                    style: GoogleFonts.inter(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.blue)),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.4),
                textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(user.email,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.text3),
                textAlign: TextAlign.center),
              const SizedBox(height: 14),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(99), border: Border.all(color: roleColor.withValues(alpha: 0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(roleIcon, size: 15, color: roleColor),
                  const SizedBox(width: 6),
                  Text(user.role.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor, letterSpacing: 0.06)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Info section ─────────────────────────────────────────────────
          _SectionCard(
            label: 'Account Information',
            icon: Icons.person_outline_rounded,
            children: [
              _InfoRow(icon: Icons.badge_outlined, label: 'Full Name', value: user.name),
              const _Divider(),
              _InfoRow(icon: Icons.email_outlined, label: 'Email Address', value: user.email),
              const _Divider(),
              _InfoRow(icon: Icons.shield_outlined, label: 'Role', value: _roleLabel(user.role), valueColor: roleColor),
            ],
          ),

          const SizedBox(height: 8),

          // ── Permissions section ──────────────────────────────────────────
          _SectionCard(
            label: 'Permissions',
            icon: Icons.lock_outline_rounded,
            children: [
              _PermRow(label: 'View Projects',   granted: true),
              const _Divider(),
              _PermRow(label: 'Create Projects', granted: user.isManager),
              const _Divider(),
              _PermRow(label: 'Manage Tasks',    granted: user.isManager),
              const _Divider(),
              _PermRow(label: 'Manage Users',    granted: user.isAdmin),
              const _Divider(),
              _PermRow(label: 'Admin Panel',     granted: user.isAdmin),
            ],
          ),

          const SizedBox(height: 24),

          // ── Logout button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LogoutButton(ref: ref),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Cipher Task Management · v1.0.0',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.text4)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _roleLabel(String r) => switch (r) {
    'admin'   => 'Administrator — Full access',
    'manager' => 'Manager — Projects & Tasks',
    _         => 'Member — View & Update assigned tasks',
  };
}

class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.label, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.text3),
          const SizedBox(width: 6),
          Text(label.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.08)),
        ]),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.text3),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.text)),
      ])),
    ]),
  );
}

class _PermRow extends StatelessWidget {
  final String label;
  final bool granted;
  const _PermRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    child: Row(children: [
      Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text2)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: granted ? AppColors.greenLight : AppColors.redLight,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(granted ? Icons.check_rounded : Icons.close_rounded,
            size: 12, color: granted ? AppColors.green : AppColors.red),
          const SizedBox(width: 4),
          Text(granted ? 'Allowed' : 'Denied',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
              color: granted ? AppColors.green : AppColors.red)),
        ]),
      ),
    ]),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 62),
    child: Divider(height: 1, color: AppColors.borderLight),
  );
}

class _LogoutButton extends ConsumerWidget {
  final WidgetRef ref;
  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
            content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: AppColors.text3, fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.text3, fontWeight: FontWeight.w600))),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Text('Sign Out', style: GoogleFonts.inter(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    ),
  );
}
