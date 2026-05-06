import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
        title: Text('Dashboard', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: () { ref.invalidate(dashboardProvider); _ctrl.forward(from: 0); },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(
                  (auth.user?.name.isNotEmpty == true ? auth.user!.name[0] : 'U').toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                )),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
            ),
          ),
        ),
      ),
      drawer: _AppDrawer(auth: auth),
      body: statsAsync.when(
        loading: () => _shimmer(),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
        data: (stats) => FadeTransition(
          opacity: _fade,
          child: _body(context, auth, stats),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AuthState auth, Map<String, dynamic> stats) {
    final total  = (stats['total_tasks'] as int? ?? 0);
    final done   = (stats['done_tasks'] as int? ?? 0);
    final inProg = (stats['in_progress_tasks'] as int? ?? 0);
    final todo   = (total - done - inProg).clamp(0, total);
    final pct    = total > 0 ? (done / total * 100).round() : 0;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: CustomScrollView(
        slivers: [
          // ── Gradient Hero Banner ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good ${_greeting()}, ${auth.user?.name.split(' ').first ?? 'User'}! 👋',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text("Here's your workspace at a glance",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
                const SizedBox(height: 16),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_roleIcon(auth.user?.role), size: 13, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text('${(auth.user?.role ?? 'member').toUpperCase()} ACCESS',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.08)),
                  ]),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.4,
                  children: [
                    _StatCard(label: 'Projects',   value: '${stats['total_projects'] ?? 0}', icon: Icons.folder_rounded,       colors: const [Color(0xFF2563EB), Color(0xFF60A5FA)]),
                    _StatCard(label: 'Active',     value: '${stats['active_projects'] ?? 0}', icon: Icons.bolt_rounded,          colors: const [Color(0xFF059669), Color(0xFF34D399)]),
                    _StatCard(label: 'Tasks Done', value: '$done',                            icon: Icons.check_rounded,           colors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
                    _StatCard(label: 'Members',    value: '${stats['total_members'] ?? 0}',   icon: Icons.people_alt_rounded,     colors: const [Color(0xFFD97706), Color(0xFFFBBF24)]),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Completion card
                _progressCard(pct, done, total, inProg, todo),
                const SizedBox(height: 16),
                // Chart card
                _chartCard(todo.toDouble(), inProg.toDouble(), done.toDouble()),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Recent Projects',
                  action: 'View all',
                  onAction: () => Navigator.of(context).pushNamed('/projects'),
                ),
                ...(stats['recent_projects'] as List<dynamic>? ?? []).take(3).map((p) => _projectTile(context, p)),
                if ((stats['recent_projects'] as List<dynamic>? ?? []).isEmpty)
                  const EmptyState(icon: Icons.folder_open_rounded, title: 'No projects yet', subtitle: 'Create your first project'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(int pct, int done, int total, int inProg, int todo) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Overall Completion', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('$pct%', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: total > 0 ? done / total : 0,
          minHeight: 10,
          backgroundColor: const Color(0xFFF0F4FF),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _legend('Todo', todo, AppColors.amber),
        const SizedBox(width: 16),
        _legend('In Progress', inProg, AppColors.blue),
        const SizedBox(width: 16),
        _legend('Done', done, AppColors.green),
      ]),
    ]),
  );

  Widget _legend(String l, int v, Color c) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text('$l: $v', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)),
  ]);

  Widget _chartCard(double todo, double prog, double done) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Task Distribution', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      SizedBox(
        height: 150,
        child: BarChart(BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF0F4FF), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) {
                const labels = ['Todo', 'In Progress', 'Done'];
                if (v.toInt() >= labels.length) return const SizedBox();
                return Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[v.toInt()], style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w500)));
              },
            )),
          ),
          barGroups: [_bar(0, todo, AppColors.amber), _bar(1, prog, AppColors.blue), _bar(2, done, AppColors.green)],
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              const labels = ['Todo', 'In Progress', 'Done'];
              return BarTooltipItem('${labels[group.x]}\n${rod.toY.toInt()}',
                GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white));
            },
          )),
        )),
      ),
    ]),
  );

  BarChartGroupData _bar(int x, double y, Color color) => BarChartGroupData(x: x, barRods: [
    BarChartRodData(
      toY: y.isNaN || y < 0 ? 0 : y, color: color, width: 36,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      backDrawRodData: BackgroundBarChartRodData(show: true, toY: (y + 2).clamp(1, 999), color: color.withValues(alpha: 0.06)),
    ),
  ]);

  Widget _projectTile(BuildContext context, dynamic p) {
    final status = p['status'] as String? ?? 'active';
    final (color, bg) = _statusStyle(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(width: 44, height: 44,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Icon(Icons.folder_rounded, color: color, size: 20)),
        title: Text(p['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(p['description'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: StatusChip(label: status, color: color, bg: bg),
        onTap: () => Navigator.of(context).pushNamed('/projects/${p['id']}'),
      ),
    );
  }

  String _greeting() { final h = DateTime.now().hour; return h < 12 ? 'morning' : h < 17 ? 'afternoon' : 'evening'; }
  Color _roleColor(String? r) => switch (r) { 'admin' => AppColors.red, 'manager' => AppColors.blue, _ => AppColors.green };
  IconData _roleIcon(String? r) => switch (r) { 'admin' => Icons.admin_panel_settings_rounded, 'manager' => Icons.manage_accounts_rounded, _ => Icons.person_rounded };
  (Color, Color) _statusStyle(String s) => switch (s) { 'completed' => (AppColors.green, AppColors.greenLight), 'on_hold' => (AppColors.amber, AppColors.amberLight), _ => (AppColors.blue, AppColors.blueLight) };

  Widget _shimmer() => ListView(padding: const EdgeInsets.all(20),
    children: List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerCard())));
}

// ── Compact minimal stat card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;
  const _StatCard({required this.label, required this.value, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: colors.first.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Row(children: [
      // Icon circle
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      // Text
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5, height: 1.1)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.82))),
      ])),
    ]),
  );
}


// ── Shared Drawer ────────────────────────────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  final AuthState auth;
  const _AppDrawer({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    backgroundColor: Colors.white,
    child: SafeArea(
      child: Column(children: [
        // Gradient header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
          ),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4))),
              child: Center(child: Text(
                (auth.user?.name.isNotEmpty == true ? auth.user!.name[0] : 'U').toUpperCase(),
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.user?.name ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(auth.user?.email ?? '', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        _tile(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard', const Color(0xFF2563EB)),
        _tile(context, Icons.folder_rounded, 'Projects', '/projects', const Color(0xFF7C3AED)),
        _tile(context, Icons.person_rounded, 'Profile', '/profile', const Color(0xFF059669)),
        const Spacer(),
        const Divider(),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout_rounded, color: AppColors.red, size: 18)),
          title: Text('Logout', style: GoogleFonts.inter(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 14)),
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );

  ListTile _tile(BuildContext context, IconData icon, String label, String route, Color color) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
    onTap: () { Navigator.of(context).pop(); Navigator.of(context).pushNamed(route); },
  );
}
