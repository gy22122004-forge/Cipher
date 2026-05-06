import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/project_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/shared_widgets.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _search = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: () => ref.invalidate(projectsProvider)),
        ],
      ),
      floatingActionButton: auth.user?.isManager == true
          ? FloatingActionButton.extended(
              onPressed: () => _showCreate(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text('New Project', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(children: [
              TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  fillColor: AppColors.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'active', 'completed', 'on_hold'].map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.replaceAll('_', ' ').toUpperCase()),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.blue,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.text3,
                        ),
                        backgroundColor: AppColors.bg,
                        side: BorderSide(color: selected ? AppColors.blue : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          // Project list
          Expanded(
            child: projectsAsync.when(
              loading: () => ListView(padding: const EdgeInsets.all(16), children: List.generate(4, (_) => const ShimmerCard())),
              error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(projectsProvider)),
              data: (projects) {
                final filtered = projects.where((p) {
                  final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search) || p.description.toLowerCase().contains(_search);
                  final matchFilter = _filter == 'all' || p.status == _filter;
                  return matchSearch && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.folder_off_rounded,
                    title: _search.isNotEmpty ? 'No results found' : 'No projects yet',
                    subtitle: _search.isNotEmpty ? 'Try a different search term' : 'Create your first project to get started',
                    actionLabel: auth.user?.isManager == true ? 'Create Project' : null,
                    onAction: () => _showCreate(context, ref),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _ProjectCard(project: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final form   = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
            key: form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              Text('Create New Project', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: 20),
              const FieldLabel(text: 'Project Name', required: true),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Enter project name', prefixIcon: Icon(Icons.folder_outlined, size: 20)),
                validator: (v) => v == null || v.trim().length < 2 ? 'Name must be at least 2 characters' : null,
              ),
              const SizedBox(height: 14),
              const FieldLabel(text: 'Description'),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Brief project description...', alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  loading: loading,
                  label: 'Create Project',
                  icon: Icons.add_rounded,
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    setModal(() => loading = true);
                    try {
                      await ApiService().post(Endpoints.projects, {
                        'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      });
                      ref.invalidate(projectsProvider);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Project created successfully!'),
                          backgroundColor: AppColors.green,
                        ));
                      }
                    } catch (e) {
                      setModal(() => loading = false);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.red,
                      ));
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _statusStyle(project.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pushNamed('/projects/${project.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.folder_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (project.owner != null)
                    Text('Owner: ${project.owner!.name}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                ])),
                StatusChip(label: project.status, color: color, bg: bg),
              ]),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(project.description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.task_alt_rounded, size: 13, color: AppColors.text4),
                const SizedBox(width: 4),
                Text('${project.tasks.length} tasks', style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                const Spacer(),
                if (project.deadline != null)
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: AppColors.text4),
                    const SizedBox(width: 4),
                    Text(_formatDate(project.deadline!), style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
                  ]),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text4),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  (Color, Color) _statusStyle(String s) => switch (s) {
    'completed' => (AppColors.green, AppColors.greenLight),
    'on_hold'   => (AppColors.amber, AppColors.amberLight),
    _           => (AppColors.blue, AppColors.blueLight),
  };
}
