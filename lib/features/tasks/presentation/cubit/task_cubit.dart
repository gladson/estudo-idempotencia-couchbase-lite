import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart' as res;
import '../../../../core/utils/pagination_helper.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/add_multiple_tasks.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/update_task.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final GetAllTasks getAllTasksUseCase;
  final AddTask addTaskUseCase;
  final UpdateTask updateTaskUseCase;
  final DeleteTask deleteTaskUseCase;
  final AddMultipleTasks addMultipleTasksUseCase;

  TaskCubit({
    required this.getAllTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.addMultipleTasksUseCase,
  }) : super(TaskInitial());

  Future<void> loadTasks() async {
    emit(TaskLoading());
    final result = await getAllTasksUseCase(NoParams());

    if (result is res.Success<List<Task>>) {
      _applyFiltersAndPagination(
        allTasks: result.data,
        filter: TaskFilter.all,
        query: '',
        page: 0,
      );
    } else if (result is res.Failure<List<Task>>) {
      emit(TaskError(result.failure.toString()));
    }
  }

  /// Recarrega as tarefas do banco de dados sem mostrar um indicador de loading.
  /// Usado para sincronizar o estado após uma operação bem-sucedida.
  Future<void> _refreshTasks() async {
    final result = await getAllTasksUseCase(NoParams());
    if (result is res.Success<List<Task>> && state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      _applyFiltersAndPagination(
        allTasks: result.data,
        filter: currentState.currentFilter,
        query: currentState.searchQuery,
        page: currentState.currentPage,
      );
    } else if (result is res.Failure<List<Task>>) {
      emit(TaskError(result.failure.toString()));
    }
  }

  Future<void> addNewTask(String description) async {
    if (state is! TaskLoaded) return;
    final currentState = state as TaskLoaded;

    final taskToAdd = Task(
      id: '', // O ID será gerado pelo banco
      idg: const Uuid().v4(),
      description: description,
      completed: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // A UI pode mostrar um loading aqui se desejado, mas como é local, será rápido.
    final result = await addTaskUseCase(taskToAdd);

    if (result is res.Success<String>) {
      // Cria a tarefa final com o ID retornado pelo banco
      final newTask = Task(
        id: result.data,
        idg: taskToAdd.idg,
        description: taskToAdd.description,
        completed: taskToAdd.completed,
        createdAt: taskToAdd.createdAt,
      );
      // Adiciona a nova tarefa à lista e atualiza a UI
      final newAllTasks = [newTask, ...currentState.allTasks];
      _applyFiltersAndPagination(
          allTasks: newAllTasks,
          filter: currentState.currentFilter,
          query: currentState.searchQuery,
          page: currentState.currentPage);
    } else if (result is res.Failure) {
      emit(currentState.copyWith(transientError: 'Falha ao adicionar a tarefa.'));
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    if (state is! TaskLoaded) return;
    final currentState = state as TaskLoaded;

    // Atualização otimista
    final updatedTask = task.copyWith(
      completed: !task.completed,
      completedAt: !task.completed ? DateTime.now().millisecondsSinceEpoch : null,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final optimisticTasks = currentState.allTasks.map((t) => t.id == task.id ? updatedTask : t).toList();
    _applyFiltersAndPagination(allTasks: optimisticTasks, filter: currentState.currentFilter, query: currentState.searchQuery, page: currentState.currentPage);

    final result = await updateTaskUseCase(updatedTask);
    if (result is res.Failure) {
      // Reverte e mostra o erro
      emit(currentState.copyWith(transientError: 'Falha ao atualizar a tarefa.'));
    } else {
      await _refreshTasks();
    }
  }

  Future<void> softDeleteTask(Task task) async {
    if (state is! TaskLoaded) return;
    final currentState = state as TaskLoaded;

    // Atualização otimista
    final updatedTask = task.copyWith(
      deletedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final optimisticTasks = currentState.allTasks.map((t) => t.id == task.id ? updatedTask : t).toList();
    _applyFiltersAndPagination(allTasks: optimisticTasks, filter: currentState.currentFilter, query: currentState.searchQuery, page: currentState.currentPage);

    final result = await updateTaskUseCase(updatedTask);
    if (result is res.Failure) {
      emit(currentState.copyWith(transientError: 'Falha ao deletar a tarefa.'));
    } else {
      await _refreshTasks();
    }
  }

  Future<void> hardDeleteTask(String taskId) async {
    if (state is! TaskLoaded) return;
    final currentState = state as TaskLoaded;

    // Atualização otimista
    final optimisticTasks = currentState.allTasks.where((t) => t.id != taskId).toList();
    _applyFiltersAndPagination(allTasks: optimisticTasks, filter: currentState.currentFilter, query: currentState.searchQuery, page: currentState.currentPage);

    final result = await deleteTaskUseCase(DeleteTaskParams(taskId: taskId, hardDelete: true));
    if (result is res.Failure) {
      emit(currentState.copyWith(transientError: 'Falha ao deletar a tarefa permanentemente.'));
    } else {
      await _refreshTasks();
    }
  }

  void changeFilter(TaskFilter filter) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      _applyFiltersAndPagination(
        allTasks: currentState.allTasks,
        filter: filter,
        query: currentState.searchQuery,
        page: 0, // Reseta para a primeira página
      );
    }
  }

  void search(String query) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      _applyFiltersAndPagination(
        allTasks: currentState.allTasks,
        filter: currentState.currentFilter,
        query: query,
        page: 0, // Reseta para a primeira página
      );
    }
  }

  void goToPage(int page) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      _applyFiltersAndPagination(
        allTasks: currentState.allTasks,
        filter: currentState.currentFilter,
        query: currentState.searchQuery,
        page: page,
      );
    }
  }

  void nextPage() {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      if (currentState.currentPage < currentState.totalPages - 1) {
        goToPage(currentState.currentPage + 1);
      }
    }
  }

  void previousPage() {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      if (currentState.currentPage > 0) {
        goToPage(currentState.currentPage - 1);
      }
    }
  }

  Future<void> addFakeTasks() async {
    if (state is! TaskLoaded) return;
    final currentState = state as TaskLoaded;

    // Mostra uma mensagem temporária para o usuário
    emit(currentState.copyWith(transientError: 'Gerando 1.000 tarefas...'));

    final fakeTasks = List.generate(1000, (i) {
      return Task(
        id: '', // ID será gerado pelo banco
        idg: const Uuid().v4(),
        description: 'Tarefa de teste #${i + 1}',
        completed: false,
        createdAt: DateTime.now().millisecondsSinceEpoch + i,
      );
    });

    final result = await addMultipleTasksUseCase(fakeTasks);
    if (result is res.Failure) {
      emit(currentState.copyWith(transientError: 'Falha ao gerar tarefas.'));
    }
    await loadTasks(); // Recarrega tudo para mostrar o resultado
  }

  void _applyFiltersAndPagination({
    required List<Task> allTasks,
    required TaskFilter filter,
    required String query,
    required int page,
  }) {
    // 1. Aplicar filtro por status
    List<Task> filteredTasks = allTasks.where((task) {
      switch (filter) {
        case TaskFilter.active: return !task.completed && !task.isDeleted;
        case TaskFilter.completed: return task.completed && !task.isDeleted;
        case TaskFilter.deleted: return task.isDeleted;
        case TaskFilter.all: return true;
      }
    }).toList();

    // 2. Aplicar busca por texto
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filteredTasks = filteredTasks.where((task) =>
        task.description.toLowerCase().contains(lowerQuery) ||
        task.id.toLowerCase().contains(lowerQuery) ||
        task.idg.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    // 3. Aplicar paginação
    final paginationHelper = PaginationHelper(
      totalItems: filteredTasks.length,
      itemsPerPage: 100, // Mantendo o valor original de 100 itens por página
    );

    // Garante que a página solicitada é válida para evitar erros de range.
    final validPage = page.clamp(0, (paginationHelper.totalPages - 1).clamp(0, 999999));
    paginationHelper.goToPage(validPage);

    final paginatedTasks =
        filteredTasks.sublist(paginationHelper.startIndex, paginationHelper.endIndex);

    emit(TaskLoaded(
      allTasks: allTasks,
      displayedTasks: paginatedTasks,
      currentFilter: filter,
      searchQuery: query,
      currentPage: paginationHelper.currentPage,
      totalPages: paginationHelper.totalPages,
    ));
  }
}