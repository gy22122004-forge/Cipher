import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ── Reusable shimmer skeleton ──────────────────────────────────────────────
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 12});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [Color(0xFFEEEEEE), Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
          ),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const ShimmerBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ShimmerBox(width: 160, height: 14),
            const SizedBox(height: 6),
            const ShimmerBox(width: 100, height: 11),
          ]),
          const Spacer(),
          const ShimmerBox(width: 60, height: 26, radius: 99),
        ]),
        const SizedBox(height: 14),
        const ShimmerBox(width: double.infinity, height: 5, radius: 99),
      ],
    ),
  );
}

// ── Empty state widget ─────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.all(Radius.circular(24))),
              child: Icon(icon, size: 38, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: AppColors.text3), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error state widget ─────────────────────────────────────────────────────
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3), textAlign: TextAlign.center, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Chip ────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final double fontSize;

  const StatusChip({super.key, required this.label, required this.color, required this.bg, this.fontSize = 11});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(label.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.02)),
  );
}

// ── Section Header ─────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2)),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
          ),
      ],
    ),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final String? trend;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    this.trend,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            if (trend != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
                child: Text(trend!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ── Form field label ───────────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const FieldLabel({super.key, required this.text, this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
        if (required) Text(' *', style: GoogleFonts.inter(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ── Loading button ─────────────────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const LoadingButton({super.key, required this.loading, this.onPressed, required this.label, this.icon});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    ),
  );
}

// ── Priority indicator ─────────────────────────────────────────────────────
class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (priority) {
      'high'   => (AppColors.red,   AppColors.redLight,   Icons.keyboard_double_arrow_up_rounded),
      'medium' => (AppColors.amber, AppColors.amberLight, Icons.drag_handle_rounded),
      _        => (AppColors.green, AppColors.greenLight, Icons.keyboard_double_arrow_down_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(priority, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
