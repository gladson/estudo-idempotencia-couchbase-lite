import 'package:equatable/equatable.dart';

import '../../domain/entities/task.dart';

enum TaskFilter { all, active, completed, deleted }

sealed class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object> get props => [];
}

final class TaskInitial extends TaskState {}

final class TaskLoading extends TaskState {}

final class TaskLoaded extends TaskState {
  // A lista completa de tarefas, sem filtros.
  final List<Task> allTasks;
  // A lista que será exibida na tela, já filtrada e paginada.
  final List<Task> displayedTasks;
  // O estado atual dos filtros e paginação.
  final TaskFilter currentFilter;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final String? transientError;

  const TaskLoaded({
    required this.allTasks,
    required this.displayedTasks,
    this.currentFilter = TaskFilter.all,
    this.searchQuery = '',
    this.currentPage = 0,
    this.totalPages = 1,
    this.transientError,
  });

  @override
  List<Object> get props => [
        allTasks,
        displayedTasks,
        currentFilter,
        searchQuery,
        currentPage,
        totalPages,
        ?transientError,
      ];

  TaskLoaded copyWith({
    List<Task>? allTasks,
    List<Task>? displayedTasks,
    TaskFilter? currentFilter,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    String? transientError,
    bool clearTransientError = false,
  }) {
    return TaskLoaded(
      allTasks: allTasks ?? this.allTasks,
      displayedTasks: displayedTasks ?? this.displayedTasks,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      transientError:
          clearTransientError ? null : transientError ?? this.transientError,
    );
  }
}

final class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object> get props => [message];
}