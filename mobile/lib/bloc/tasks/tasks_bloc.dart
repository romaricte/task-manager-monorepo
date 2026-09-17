import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../models/task.dart';
import '../../repositories/task_repository.dart';

enum TaskFilter {
  all('Toutes'),
  todo('À faire'),
  inProgress('En cours'),
  done('Terminées');

  const TaskFilter(this.label);
  final String label;

  TaskStatus? get status => switch (this) {
    TaskFilter.all => null,
    TaskFilter.todo => TaskStatus.todo,
    TaskFilter.inProgress => TaskStatus.inProgress,
    TaskFilter.done => TaskStatus.done,
  };
}

sealed class TasksEvent {
  const TasksEvent();
}

final class TasksStarted extends TasksEvent {
  const TasksStarted();
}

final class TasksRefreshed extends TasksEvent {
  const TasksRefreshed();
}

final class TasksFilterChanged extends TasksEvent {
  const TasksFilterChanged(this.filter);
  final TaskFilter filter;
}

final class TasksSearchChanged extends TasksEvent {
  const TasksSearchChanged(this.search);
  final String search;
}

final class TaskCreated extends TasksEvent {
  const TaskCreated(this.draft);
  final TaskDraft draft;
}

final class TaskUpdated extends TasksEvent {
  const TaskUpdated({required this.id, required this.draft});
  final int id;
  final TaskDraft draft;
}

final class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.id);
  final int id;
}

final class TaskCompletionToggled extends TasksEvent {
  const TaskCompletionToggled(this.task);
  final TaskItem task;
}

enum TasksLoadStatus { initial, loading, success, actionInProgress, failure }

class TasksState {
  const TasksState({
    this.status = TasksLoadStatus.initial,
    this.tasks = const [],
    this.overview = const [],
    this.filter = TaskFilter.all,
    this.search = '',
    this.message,
    this.errorMessage,
    this.unauthorized = false,
  });

  final TasksLoadStatus status;
  final List<TaskItem> tasks;
  final List<TaskItem> overview;
  final TaskFilter filter;
  final String search;
  final String? message;
  final String? errorMessage;
  final bool unauthorized;

  int get todoCount =>
      overview.where((task) => task.status == TaskStatus.todo).length;
  int get inProgressCount =>
      overview.where((task) => task.status == TaskStatus.inProgress).length;
  int get doneCount =>
      overview.where((task) => task.status == TaskStatus.done).length;
}

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc(this._taskRepository) : super(const TasksState()) {
    on<TasksStarted>((event, emit) => _load(emit));
    on<TasksRefreshed>((event, emit) => _load(emit, showLoader: false));
    on<TasksFilterChanged>(_onFilterChanged);
    on<TasksSearchChanged>(_onSearchChanged);
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TaskDeleted>(_onDeleted);
    on<TaskCompletionToggled>(_onCompletionToggled);
  }

  final TaskRepository _taskRepository;
  TaskFilter _filter = TaskFilter.all;
  String _search = '';
  int _requestVersion = 0;

  Future<void> _onFilterChanged(
    TasksFilterChanged event,
    Emitter<TasksState> emit,
  ) async {
    _filter = event.filter;
    await _load(emit);
  }

  Future<void> _onSearchChanged(
    TasksSearchChanged event,
    Emitter<TasksState> emit,
  ) async {
    _search = event.search;
    await _load(emit, showLoader: false);
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TasksState> emit) async {
    await _runAction(
      emit,
      () => _taskRepository.createTask(event.draft),
      'Tâche ajoutée',
    );
  }

  Future<void> _onUpdated(TaskUpdated event, Emitter<TasksState> emit) async {
    await _runAction(
      emit,
      () => _taskRepository.updateTask(event.id, event.draft),
      'Tâche mise à jour',
    );
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TasksState> emit) async {
    await _runAction(
      emit,
      () => _taskRepository.deleteTask(event.id),
      'Tâche supprimée',
    );
  }

  Future<void> _onCompletionToggled(
    TaskCompletionToggled event,
    Emitter<TasksState> emit,
  ) async {
    final task = event.task;
    await _runAction(
      emit,
      () => _taskRepository.updateTask(
        task.id,
        TaskDraft(
          title: task.title,
          description: task.description ?? '',
          status: task.status == TaskStatus.done
              ? TaskStatus.todo
              : TaskStatus.done,
        ),
      ),
      task.status == TaskStatus.done ? 'Tâche rouverte' : 'Tâche terminée',
    );
  }

  Future<void> _runAction(
    Emitter<TasksState> emit,
    Future<Object?> Function() action,
    String successMessage,
  ) async {
    emit(_stateWith(status: TasksLoadStatus.actionInProgress));
    try {
      await action();
      await _load(emit, showLoader: false, message: successMessage);
    } catch (error) {
      _emitFailure(emit, error);
    }
  }

  Future<void> _load(
    Emitter<TasksState> emit, {
    bool showLoader = true,
    String? message,
  }) async {
    final requestVersion = ++_requestVersion;
    if (showLoader) emit(_stateWith(status: TasksLoadStatus.loading));
    try {
      late final List<TaskItem> tasks;
      late final List<TaskItem> overview;
      if (_filter == TaskFilter.all && _search.trim().isEmpty) {
        tasks = await _taskRepository.fetchTasks();
        overview = tasks;
      } else {
        final results = await Future.wait([
          _taskRepository.fetchTasks(status: _filter.status, search: _search),
          _taskRepository.fetchTasks(),
        ]);
        tasks = results[0];
        overview = results[1];
      }
      if (requestVersion != _requestVersion) return;
      emit(
        TasksState(
          status: TasksLoadStatus.success,
          tasks: tasks,
          overview: overview,
          filter: _filter,
          search: _search,
          message: message,
        ),
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      _emitFailure(emit, error);
    }
  }

  TasksState _stateWith({required TasksLoadStatus status}) => TasksState(
    status: status,
    tasks: state.tasks,
    overview: state.overview,
    filter: _filter,
    search: _search,
  );

  void _emitFailure(Emitter<TasksState> emit, Object error) {
    final apiError = error is ApiException
        ? error
        : const ApiException('Une erreur inattendue est survenue.');
    emit(
      TasksState(
        status: TasksLoadStatus.failure,
        tasks: state.tasks,
        overview: state.overview,
        filter: _filter,
        search: _search,
        errorMessage: apiError.message,
        unauthorized: apiError.isUnauthorized,
      ),
    );
  }
}
