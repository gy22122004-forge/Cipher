import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/project_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/shared_widgets.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final tasksAsync   = ref.watch(tasksByProjectProvider(projectId));
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: projectAsync.maybeWhen(data: (p) => Text(p.name), orElse: () => const Text('Project Detail')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.invalidate(projectDetailProvider(projectId));
              ref.invalidate(tasksByProjectProvider(projectId));
            },
          ),
        ],
      ),
      floatingActionButton: auth.user?.isManager == true
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateTask(context, ref),
              icon: const Icon(Icons.add_task_rounded),
              label: Text('Add Task', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            )
          : null,
      body: tasksAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => const ShimmerCard()),
        ),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(tasksByProjectProvider(projectId))),
        data: (tasks) {
          final todo = tasks.where((t) => t.status == 'todo').toList();
          final prog = tasks.where((t) => t.status == 'in_progress').toList();
          final done = tasks.where((t) => t.status == 'done').toList();

          return CustomScrollView(
            slivers: [
              // Project stats header
              SliverToBoxAdapter(
                child: projectAsync.maybeWhen(
                  data: (p) => Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (p.description.isNotEmpty)
                        Text(p.description, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3, height: 1.5)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _headerStat('Total', '${tasks.length}', AppColors.text2),
                        const SizedBox(width: 16),
                        _headerStat('Done', '${done.length}', AppColors.green),
                        const SizedBox(width: 16),
                        _headerStat('In Progress', '${prog.length}', AppColors.blue),
                        const SizedBox(width: 16),
                        _headerStat('Todo', '${todo.length}', AppColors.amber),
                        const Spacer(),
                        StatusChip(label: p.status, color: _statusColor(p.status), bg: _statusBg(p.status)),
                      ]),
                      if (tasks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: done.length / tasks.length,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(done.length / tasks.length * 100).round()}% complete',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
                      ],
                    ]),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ),
              // Kanban columns
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _KanbanColumn(title: 'Todo', icon: Icons.radio_button_unchecked, color: AppColors.amber, tasks: todo, projectId: projectId, ref: ref),
                    _KanbanColumn(title: 'In Progress', icon: Icons.pending_rounded, color: AppColors.blue, tasks: prog, projectId: projectId, ref: ref),
                    _KanbanColumn(title: 'Done', icon: Icons.check_circle_rounded, color: AppColors.green, tasks: done, projectId: projectId, ref: ref),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.text3, fontWeight: FontWeight.w500)),
    ],
  );

  Color _statusColor(String s) => switch (s) {
    'completed' => AppColors.green,
    'on_hold'   => AppColors.amber,
    _           => AppColors.blue,
  };

  Color _statusBg(String s) => switch (s) {
    'completed' => AppColors.greenLight,
    'on_hold'   => AppColors.amberLight,
    _           => AppColors.blueLight,
  };

  void _showCreateTask(BuildContext context, WidgetRef ref) {
    final form      = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    String priority = 'medium';
    bool loading    = false;

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
              Text('Add New Task', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: 20),
              const FieldLabel(text: 'Task Title', required: true),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.task_alt_rounded, size: 20)),
                validator: (v) => v == null || v.trim().length < 2 ? 'Title must be at least 2 characters' : null,
              ),
              const SizedBox(height: 14),
              const FieldLabel(text: 'Description'),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Optional details...'),
              ),
              const SizedBox(height: 14),
              const FieldLabel(text: 'Priority'),
              const SizedBox(height: 8),
              Row(children: ['low', 'medium', 'high'].map((p) {
                final selected = priority == p;
                final color = p == 'high' ? AppColors.red : p == 'medium' ? AppColors.amber : AppColors.green;
                final icon  = p == 'high' ? Icons.keyboard_double_arrow_up_rounded : p == 'medium' ? Icons.drag_handle_rounded : Icons.keyboard_double_arrow_down_rounded;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setModal(() => priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? color : color.withValues(alpha: 0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 14, color: selected ? Colors.white : color),
                        const SizedBox(width: 4),
                        Text(p, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
                      ]),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  loading: loading,
                  label: 'Create Task',
                  icon: Icons.add_task_rounded,
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    setModal(() => loading = true);
                    try {
                      await ApiService().post(Endpoints.projectTasks(projectId), {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'priority': priority,
                      });
                      ref.invalidate(tasksByProjectProvider(projectId));
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Task created!'),
                          backgroundColor: AppColors.green,
                        ));
                      }
                    } catch (e) {
                      setModal(() => loading = false);
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

class _KanbanColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<TaskModel> tasks;
  final String projectId;
  final WidgetRef ref;

  const _KanbanColumn({required this.title, required this.icon, required this.color, required this.tasks, required this.projectId, required this.ref});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
            child: Text('${tasks.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      ),
      if (tasks.isEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Center(child: Text('No tasks', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text4))),
        )
      else
        ...tasks.map((t) => _TaskCard(task: t, projectId: projectId, ref: ref, columnColor: color)),
      const SizedBox(height: 8),
    ],
  );
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String projectId;
  final WidgetRef ref;
  final Color columnColor;

  const _TaskCard({required this.task, required this.projectId, required this.ref, required this.columnColor});

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'done';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDone ? AppColors.greenLight : AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 4, height: 36,
              decoration: BoxDecoration(color: columnColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                task.title,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.text3,
                ),
              ),
              if (task.description.isNotEmpty)
                Text(task.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            _statusMenu(context),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            PriorityBadge(priority: task.priority),
            const Spacer(),
            if (task.assignee != null) Row(children: [
              CircleAvatar(
                radius: 10, backgroundColor: AppColors.blueLight,
                child: Text(task.assignee!.name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
              const SizedBox(width: 5),
              Text(task.assignee!.name.split(' ').first, style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
            ]) else Text('Unassigned', style: GoogleFonts.inter(fontSize: 11, color: AppColors.text4)),
          ]),
        ]),
      ),
    );
  }

  PopupMenuButton<String> _statusMenu(BuildContext context) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.text3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    itemBuilder: (_) => [
      _menuItem('todo', Icons.radio_button_unchecked, AppColors.amber, 'Mark as Todo'),
      _menuItem('in_progress', Icons.pending_rounded, AppColors.blue, 'Mark In Progress'),
      _menuItem('done', Icons.check_circle_rounded, AppColors.green, 'Mark as Done'),
    ],
    onSelected: (status) async {
      await ApiService().put(Endpoints.task(task.id), {
        'title': task.title,
        'description': task.description,
        'status': status,
        'priority': task.priority,
        'assignee_id': task.assigneeId,
      });
      ref.invalidate(tasksByProjectProvider(projectId));
    },
  );

  PopupMenuItem<String> _menuItem(String value, IconData icon, Color color, String label) => PopupMenuItem(
    value: value,
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}
