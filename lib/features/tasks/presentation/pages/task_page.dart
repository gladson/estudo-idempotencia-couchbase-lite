import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../domain/entities/task.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskCubit, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded && state.transientError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.transientError!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: const Text('Idempotência com Couchbase Lite'),
          actions: [
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Gerar 1.000 tarefas',
              onPressed: () => context.read<TaskCubit>().addFakeTasks(),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => context.read<TaskCubit>().search(value),
                decoration: InputDecoration(
                  labelText: 'Buscar tarefas...',
                  hintText: 'Digite descrição, ID ou IDG',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
              const _FilterBar(),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<TaskCubit, TaskState>(
                  builder: (context, state) {
                    if (state is TaskInitial || state is TaskLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TaskError) {
                      return Center(child: Text('Erro: ${state.message}'));
                    }
                    if (state is TaskLoaded) {
                      if (state.displayedTasks.isEmpty) {
                        return const Center(child: Text('Nenhuma tarefa encontrada.'));
                      }
                      return _TaskList(tasks: state.displayedTasks);
                    }
                    return const Center(child: Text('Estado desconhecido.'));
                  },
                ),
              ),
              BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoaded) {
                    final hasPagination = state.totalPages > 1;
                    if (!hasPagination) return const SizedBox.shrink();

                    return _PaginationBar(
                      currentPage: state.currentPage,
                      totalPages: state.totalPages,
                      onPageSelected: (page) => context.read<TaskCubit>().goToPage(page),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTaskDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Nova Tarefa'),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskCubit>(),
        child: const _AddTaskSheet(),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state is! TaskLoaded) return const SizedBox.shrink();

        final cubit = context.read<TaskCubit>();
        final activeFilter = state.currentFilter;

        int count(TaskFilter filter) {
          return state.allTasks.where((task) {
            switch (filter) {
              case TaskFilter.active: return !task.completed && !task.isDeleted;
              case TaskFilter.completed: return task.completed && !task.isDeleted;
              case TaskFilter.deleted: return task.isDeleted;
              case TaskFilter.all: return true;
            }
          }).length;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Todas (${state.allTasks.length})',
                isSelected: activeFilter == TaskFilter.all,
                onTap: () => cubit.changeFilter(TaskFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Ativas (${count(TaskFilter.active)})',
                isSelected: activeFilter == TaskFilter.active,
                onTap: () => cubit.changeFilter(TaskFilter.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Concluídas (${count(TaskFilter.completed)})',
                isSelected: activeFilter == TaskFilter.completed,
                onTap: () => cubit.changeFilter(TaskFilter.completed),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Deletadas (${count(TaskFilter.deleted)})',
                isSelected: activeFilter == TaskFilter.deleted,
                onTap: () => cubit.changeFilter(TaskFilter.deleted),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        // Usamos a chave para garantir que o Flutter identifique o widget
        // corretamente ao adicionar ou remover itens.
        return _TaskListItem(task: task);
      },
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  const _TaskListItem({required this.task});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? cardColor;
    if (task.isDeleted) {
      cardColor = theme.colorScheme.errorContainer.withAlpha(75);
    } else if (task.completed) {
      cardColor = theme.colorScheme.surfaceContainerHighest;
    } else {
      cardColor = theme.colorScheme.secondaryContainer.withAlpha(75);
    }

    return Slidable(
      key: ValueKey(task.idg),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              if (task.isDeleted) {
                context.read<TaskCubit>().hardDeleteTask(task.id);
              } else {
                context.read<TaskCubit>().softDeleteTask(task);
              }
            },
            backgroundColor: task.isDeleted ? Colors.red.shade900 : theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: task.isDeleted ? Icons.delete_forever : Icons.delete_outline,
            label: task.isDeleted ? 'Excluir' : 'Deletar',
          ),
        ],
      ),
      child: RepaintBoundary(
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          fontStyle: task.completed ? FontStyle.italic : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Checkbox(
                      value: task.completed,
                      onChanged: task.isDeleted
                          ? null
                          : (_) => context.read<TaskCubit>().toggleTaskCompletion(task),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _InfoChip(label: 'ID', value: task.id),
                    _InfoChip(label: 'IDG', value: task.idg),
                    _InfoChip(label: 'Criada em', value: _formatTimestamp(task.createdAt)),
                    if (task.updatedAt != null)
                      _InfoChip(label: 'Atualizada em', value: _formatTimestamp(task.updatedAt!)),
                    if (task.completedAt != null)
                      _InfoChip(label: 'Completada em', value: _formatTimestamp(task.completedAt!)),
                    if (task.deletedAt != null)
                      _InfoChip(label: 'Deletada em', value: _formatTimestamp(task.deletedAt!)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatTimestamp(int ts) {
    final date = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      label: Text(
        '$label: $value',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Foca no campo de texto assim que a janela abre.
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<TaskCubit>().addNewTask(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // O Padding se ajusta para que o teclado não cubra o conteúdo.
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(labelText: 'Descrição da Nova Tarefa'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: const Text('Salvar Tarefa'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageSelected;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: currentPage > 0 ? () => onPageSelected(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0 ? () => onPageSelected(currentPage - 1) : null,
          ),
          Text('Página ${currentPage + 1} de $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1 ? () => onPageSelected(currentPage + 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: currentPage < totalPages - 1 ? () => onPageSelected(totalPages - 1) : null,
          ),
        ],
      ),
    );
  }
}