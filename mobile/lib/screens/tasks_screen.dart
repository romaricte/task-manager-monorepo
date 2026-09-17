import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../bloc/tasks/tasks_bloc.dart';
import '../core/app_colors.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../widgets/momentum_brand.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    context.read<TasksBloc>().add(const TasksStarted());
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => context.read<TasksBloc>().add(TasksSearchChanged(value)),
    );
  }

  Future<void> _openEditor([TaskItem? task]) async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorSheet(task: task),
    );
    if (draft == null || !mounted) return;
    context.read<TasksBloc>().add(
      task == null
          ? TaskCreated(draft)
          : TaskUpdated(id: task.id, draft: draft),
    );
  }

  Future<void> _confirmDelete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.coralDark,
          ),
        ),
        title: const Text('Supprimer cette tâche ?'),
        content: Text('« ${task.title} » sera supprimée définitivement.'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coralDark),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<TasksBloc>().add(TaskDeleted(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TasksBloc, TasksState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.errorMessage != current.errorMessage ||
          current.unauthorized,
      listener: (context, state) {
        if (state.unauthorized) {
          context.read<AuthBloc>().add(const AuthLogoutRequested());
          return;
        }
        final message = state.message ?? state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: state.errorMessage == null
                    ? AppColors.ink
                    : AppColors.coralDark,
              ),
            );
        }
      },
      builder: (context, state) {
        final isBusy = state.status == TasksLoadStatus.actionInProgress;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    _DashboardHeader(user: widget.user),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.coral,
                        onRefresh: () async {
                          context.read<TasksBloc>().add(const TasksRefreshed());
                          await context.read<TasksBloc>().stream.firstWhere(
                            (next) => next.status != TasksLoadStatus.loading,
                          );
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                              sliver: SliverToBoxAdapter(
                                child: _SummaryCards(state: state),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                              sliver: SliverToBoxAdapter(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher une tâche…',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: 'Effacer la recherche',
                                            onPressed: () {
                                              _searchController.clear();
                                              _onSearchChanged('');
                                              setState(() {});
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 64,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  itemCount: TaskFilter.values.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final filter = TaskFilter.values[index];
                                    return ChoiceChip(
                                      label: Text(filter.label),
                                      selected: state.filter == filter,
                                      onSelected: (_) => context
                                          .read<TasksBloc>()
                                          .add(TasksFilterChanged(filter)),
                                      selectedColor: AppColors.ink,
                                      backgroundColor: const Color(0xFFE8E4DB),
                                      labelStyle: TextStyle(
                                        color: state.filter == filter
                                            ? Colors.white
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (state.status == TasksLoadStatus.loading &&
                                state.tasks.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.coral,
                                  ),
                                ),
                              )
                            else if (state.status == TasksLoadStatus.failure &&
                                state.tasks.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _ErrorState(
                                  message:
                                      state.errorMessage ??
                                      'Impossible de charger vos tâches.',
                                  onRetry: () => context.read<TasksBloc>().add(
                                    const TasksStarted(),
                                  ),
                                ),
                              )
                            else if (state.tasks.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(
                                  filtered:
                                      state.filter != TaskFilter.all ||
                                      state.search.isNotEmpty,
                                  onAdd: _openEditor,
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  110,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: state.tasks.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final task = state.tasks[index];
                                    return TaskCard(
                                      task: task,
                                      disabled: isBusy,
                                      onToggle: () => context
                                          .read<TasksBloc>()
                                          .add(TaskCompletionToggled(task)),
                                      onEdit: () => _openEditor(task),
                                      onDelete: () => _confirmDelete(task),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isBusy ? null : _openEditor,
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nouvelle tâche',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.trim().split(RegExp(r'\s+')).first;
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MomentumBrand(light: true, compact: true),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.mint,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Se déconnecter',
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFAFC1BD),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            _dateLabel(DateTime.now()).toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Bonjour $firstName ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Avancez sereinement, une tâche à la fois.',
            style: TextStyle(color: Color(0xFF9EB3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final TasksState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: state.overview.length,
            label: 'Toutes',
            icon: Icons.list_alt_rounded,
            color: AppColors.coral,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            value: state.inProgressCount,
            label: 'En cours',
            icon: Icons.schedule_rounded,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            value: state.doneCount,
            label: 'Terminées',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.mint,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.ink, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.disabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final bool disabled;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(task.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 6, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: task.status == TaskStatus.done
                ? 'Rouvrir la tâche'
                : 'Terminer la tâche',
            button: true,
            child: InkWell(
              onTap: disabled ? null : onToggle,
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: task.status == TaskStatus.done
                      ? AppColors.mintDark
                      : style.$1,
                  border: Border.all(color: style.$2, width: 1.5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: task.status == TaskStatus.done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.status == TaskStatus.done
                        ? AppColors.muted
                        : AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: style.$1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      task.status.label,
                      style: TextStyle(
                        color: style.$2,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !disabled,
            tooltip: 'Actions de la tâche',
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 19),
                    SizedBox(width: 10),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.coralDark,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Supprimer',
                      style: TextStyle(color: AppColors.coralDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusStyle(TaskStatus status) => switch (status) {
    TaskStatus.todo => (const Color(0xFFEDEBE5), const Color(0xFF66706E)),
    TaskStatus.inProgress => (const Color(0xFFF7E4AD), const Color(0xFF77591A)),
    TaskStatus.done => (const Color(0xFFD7EEE2), AppColors.mintDark),
  };
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _status = widget.task?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.task == null ? 'Nouvelle priorité' : 'Mise à jour',
                    style: const TextStyle(
                      color: AppColors.coralDark,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.task == null
                        ? 'Ajouter une tâche'
                        : 'Modifier la tâche',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Titre',
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Le titre est obligatoire'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnelle)',
                      alignLabelWithHint: true,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Statut',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskStatus.values
                        .map(
                          (status) => ChoiceChip(
                            label: Text(status.label),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                            selectedColor: AppColors.ink,
                            backgroundColor: const Color(0xFFE8E4DB),
                            labelStyle: TextStyle(
                              color: _status == status
                                  ? Colors.white
                                  : AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(
                          context,
                          TaskDraft(
                            title: _titleController.text.trim(),
                            description: _descriptionController.text.trim(),
                            status: _status,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.task == null
                            ? 'Ajouter la tâche'
                            : 'Enregistrer',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onAdd});

  final bool filtered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.mintDark,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              filtered
                  ? 'Aucune tâche ne correspond'
                  : 'Votre journée est toute neuve',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Essayez un autre filtre ou une recherche différente.'
                  : 'Ajoutez votre première tâche et commencez à avancer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!filtered) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter une tâche'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.coralDark,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Impossible de charger vos tâches',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
