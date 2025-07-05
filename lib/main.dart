import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math';

import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:cbl/cbl.dart';

import 'package:uuid/uuid.dart'; // Para gerar IDs únicos

enum TaskFilter { all, active, completed, deleted }

class TaskCubit extends Cubit<List<Map<String, dynamic>>> {
  TaskCubit() : super([]);

  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  String _searchQuery = '';
  TaskFilter currentFilter = TaskFilter.all;
  
  // Controles de paginação
  static const int _itemsPerPage = 100;
  int _currentPage = 0;
  bool _hasPagination = false;

  void setTasks(List<Map<String, dynamic>> tasks) {
    _allTasks = tasks;
    _applyFilters();
  }

  void updateTask(String id, Map<String, dynamic> newTask) {
    final updated = _allTasks.map((task) {
      if (task['_id'] == id) {
        return {...task, ...newTask};
      }
      return task;
    }).toList();
    _allTasks = updated;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _currentPage = 0; // Reset para primeira página
    _applyFilters();
  }

  void setFilter(TaskFilter filter) {
    currentFilter = filter;
    _currentPage = 0; // Reset para primeira página
    _applyFilters();
  }

  // Métodos de paginação
  void nextPage() {
    if (_hasPagination && _currentPage < totalPages - 1) {
      _currentPage++;
      _applyPagination();
    }
  }

  void previousPage() {
    if (_hasPagination && _currentPage > 0) {
      _currentPage--;
      _applyPagination();
    }
  }

  void goToPage(int page) {
    if (_hasPagination && page >= 0 && page < totalPages) {
      _currentPage = page;
      _applyPagination();
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filteredTasks = _allTasks;

    // Aplicar filtro por status
    switch (currentFilter) {
      case TaskFilter.active:
        filteredTasks = _allTasks.where((task) {
          final taskData = task['tasks'] ?? {};
          return taskData['deletedAt'] == null && taskData['completed'] != true;
        }).toList();
        break;
      case TaskFilter.completed:
        filteredTasks = _allTasks.where((task) {
          final taskData = task['tasks'] ?? {};
          return taskData['deletedAt'] == null && taskData['completed'] == true;
        }).toList();
        break;
      case TaskFilter.deleted:
        filteredTasks = _allTasks.where((task) {
          final taskData = task['tasks'] ?? {};
          return taskData['deletedAt'] != null;
        }).toList();
        break;
      case TaskFilter.all:
      default:
        // Não filtrar por status
        break;
    }

    // Aplicar busca por texto
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final taskData = task['tasks'] ?? {};
        final description = (taskData['description'] ?? '').toString().toLowerCase();
        final idg = (taskData['idg'] ?? '').toString().toLowerCase();
        final id = (task['_id'] ?? '').toString().toLowerCase();
        
        return description.contains(_searchQuery) || 
               idg.contains(_searchQuery) || 
               id.contains(_searchQuery);
      }).toList();
    }

    _filteredTasks = filteredTasks;
    _hasPagination = _filteredTasks.length > _itemsPerPage;
    
    // Reset para primeira página se necessário
    if (_currentPage >= totalPages) {
      _currentPage = 0;
    }
    
    _applyPagination();
  }

  void _applyPagination() {
    if (!_hasPagination) {
      emit(_filteredTasks);
      return;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredTasks.length);
    final paginatedTasks = _filteredTasks.sublist(startIndex, endIndex);
    
    emit(paginatedTasks);
  }

  // Getters para estatísticas
  int get totalTasks => _allTasks.length;
  int get activeTasks => _allTasks.where((task) {
    final taskData = task['tasks'] ?? {};
    return taskData['deletedAt'] == null && taskData['completed'] != true;
  }).length;
  int get completedTasks => _allTasks.where((task) {
    final taskData = task['tasks'] ?? {};
    return taskData['deletedAt'] == null && taskData['completed'] == true;
  }).length;
  int get deletedTasks => _allTasks.where((task) {
    final taskData = task['tasks'] ?? {};
    return taskData['deletedAt'] != null;
  }).length;

  // Getters para paginação
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => (_filteredTasks.length / _itemsPerPage).ceil();
  bool get hasPagination => _hasPagination;
  bool get hasNextPage => _currentPage < totalPages - 1;
  bool get hasPreviousPage => _currentPage > 0;
  int get displayedItemsCount => _filteredTasks.length;
  int get currentPageStartItem => _currentPage * _itemsPerPage + 1;
  int get currentPageEndItem => ((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredTasks.length);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CouchbaseLiteFlutter.init();
  runApp(
    BlocProvider(
      create: (_) => TaskCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Idempotência com Couchbase Lite',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system, // Segue a preferência do sistema
      home: IdempotenceDemoScreen(),
    );
  }
}

class IdempotenceDemoScreen extends StatefulWidget {
  const IdempotenceDemoScreen({super.key});

  @override
  IdempotenceDemoScreenState createState() => IdempotenceDemoScreenState();
}

class IdempotenceDemoScreenState extends State<IdempotenceDemoScreen> {
  Database? _database;
  final Uuid _uuid = Uuid();
  final TextEditingController _taskDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabaseAndLoadTasks();
  }

  @override
  void dispose() {
    _database?.close();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _initDatabaseAndLoadTasks() async {
    try {
      final dbDir = Directory(p.join(Directory.current.path, 'db'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        if (kDebugMode) print('Pasta db criada em: ${dbDir.path}');
      }

      _database = await Database.openAsync(
        'tasks_idempotence_db',
        DatabaseConfiguration(directory: dbDir.path),
      );
      if (kDebugMode) {
        print("Banco de dados 'tasks_idempotence_db' aberto em ${dbDir.path}");
      }
      
      // Criar coleção se não existir
      try {
        await _database!.createCollection('tasks');
      } catch (e) {
        // Coleção já existe
        if (kDebugMode) {
          print("Coleção 'tasks' já existe ou erro ao criar: $e");
        }
      }
      
      await _loadTasks();
    } catch (e) {
      _showSnackBar("Erro ao inicializar o banco de dados: $e", Colors.red);
      if (kDebugMode) {
        print("Erro: $e");
      }
    }
  }

  Future<void> _loadTasks() async {
    if (_database == null) return;

    try {
      if (kDebugMode) {
        print("Carregando tarefas...");
        // Listar todas as coleções
        final collections = await _database!.collections();
        print("Coleções disponíveis: ${collections.map((c) => c.name).toList()}");
      }
      
      final query = await _database!.createQuery('''
        SELECT meta().id as _id, tasks.*
        FROM tasks
        WHERE type = 'task'
        ORDER BY createdAt ASC
      ''');

      final result = await query.execute();
      final results = await result.allResults();
      final fetchedTasks = results.map((result) => result.toPlainMap()).toList();

      if (kDebugMode) {
        print("Query executada. Resultados encontrados: ${results.length}");
        print("Dados das tarefas: $fetchedTasks");
        print("Tarefas carregadas (debug): $fetchedTasks");
      }

      if (!mounted) return;
      context.read<TaskCubit>().setTasks(fetchedTasks);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Erro ao carregar tarefas: $e", Colors.red);
      if (kDebugMode) {
        print("Erro ao carregar tarefas: $e");
      }
    }
  }

  // --- Implementação da Idempotência (Criação de Tarefa) ---
  Future<void> _addTask(String description) async {
    if (_database == null || description.isEmpty) return;

    final taskIdg = _uuid.v4();
    final taskDoc = MutableDocument({
      'type': 'task',
      'idg': taskIdg,
      'description': description,
      'completed': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      final collection = await _database!.collection('tasks');
      await collection!.saveDocument(taskDoc);
      
      if (!mounted) return;

      // Adicione a nova tarefa diretamente ao Cubit (sem recarregar do banco)
      final tasks = context.read<TaskCubit>().state;
      final newTask = {
        '_id': taskDoc.id,
        'tasks': {
          'type': 'task',
          'idg': taskIdg,
          'description': description,
          'completed': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }
      };
      final updatedTasks = [...tasks, newTask];
      context.read<TaskCubit>().setTasks(updatedTasks);
      
      _showSnackBar("Tarefa '$description' adicionada (IDG: $taskIdg).", Colors.green);
    } catch (e) {
      _showSnackBar("Erro ao adicionar tarefa: $e", Colors.red);
      if (kDebugMode) {
        print("Erro ao adicionar tarefa: $e");
      }
    }
  }

  // --- Implementação da Idempotência (Completar Tarefa) ---
  void _atualizarBanco(String taskId, bool currentValue) async {
    if (_database == null) return;

    // Atualize o estado local imediatamente (UI responde na hora)
    final tasks = context.read<TaskCubit>().state;
    final updatedTasks = tasks.map((task) {
      if (task['_id'] == taskId) {
        final taskData = task['tasks'] ?? {};
        if (taskData['deletedAt'] == null) {
          final newTaskData = Map<String, dynamic>.from(taskData)
            ..['completed'] = !currentValue
            ..['completedAt'] = !currentValue ? DateTime.now().millisecondsSinceEpoch : null;
          return {...task, 'tasks': newTaskData};
        }
      }
      return task;
    }).toList();
    context.read<TaskCubit>().setTasks(updatedTasks);

    // Agora atualize no banco normalmente (em background)
    Future(() async {
      try {
        final taskDoc = await (await _database!.collection('tasks'))?.document(taskId);
        if (taskDoc == null) return;
        final mutableTaskDoc = taskDoc.toMutable();
        mutableTaskDoc.setBoolean(key: 'completed', !currentValue);
        if (!currentValue) {
          mutableTaskDoc.setValue(key: 'completedAt', DateTime.now().millisecondsSinceEpoch);
        } else {
          mutableTaskDoc.setValue(key: 'completedAt', null);
        }
        mutableTaskDoc.setValue(key: 'updatedAt', DateTime.now().millisecondsSinceEpoch);
        await (await _database!.collection('tasks'))?.saveDocument(mutableTaskDoc);
        await _loadTasks();
      } catch (e) {
        _showSnackBar("Erro ao atualizar tarefa: $e", Colors.red);
      }
    });
  }

  Future<void> _softDeleteTask(String taskId) async {
    if (_database == null) return;

    // Atualize o estado local imediatamente
    final tasks = context.read<TaskCubit>().state;
    final updatedTasks = tasks.map((task) {
      if (task['_id'] == taskId) {
        final taskData = task['tasks'] ?? {};
        final newTaskData = Map<String, dynamic>.from(taskData)
          ..['deletedAt'] = DateTime.now().millisecondsSinceEpoch
          ..['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        return {...task, 'tasks': newTaskData};
      }
      return task;
    }).toList();
    context.read<TaskCubit>().setTasks(updatedTasks);

    // Agora atualize no banco normalmente (em background)
    try {
      final collection = await _database!.collection('tasks');
      final taskDoc = await collection?.document(taskId);
      if (taskDoc == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final mutableTaskDoc = taskDoc.toMutable();
      mutableTaskDoc.setValue(key: 'deletedAt', now);
      mutableTaskDoc.setValue(key: 'updatedAt', now);
      await collection?.saveDocument(mutableTaskDoc);
      await _loadTasks();
    } catch (e) {
      _showSnackBar("Erro ao deletar tarefa: $e", Colors.red);
    }
  }

  Future<void> _hardDeleteTask(String taskId) async {
    if (_database == null) return;
    final collection = await _database!.collection('tasks');
    final doc = await collection?.document(taskId);
    if (doc == null) return;
    await collection?.deleteDocument(doc);
    await _loadTasks();
  }

  Future<void> _criarDezMilTarefas() async {
    if (_database == null) return;
    final collection = await _database!.collection('tasks');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 10000; i++) {
      final taskIdg = _uuid.v4();
      final taskDoc = MutableDocument({
        'type': 'task',
        'idg': taskIdg,
        'description': 'Tarefa aleatória #$i',
        'completed': false,
        'createdAt': now + i,
      });
      await collection!.saveDocument(taskDoc);
    }
    _showSnackBar('10.000 tarefas criadas!', Colors.green);
    await _loadTasks();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idempotência com Couchbase Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Criar 10k aleatório',
            onPressed: () async {
              await _criarDezMilTarefas();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo de busca
            TextField(
              onChanged: (value) {
                context.read<TaskCubit>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                labelText: 'Buscar tarefas...',
                hintText: 'Digite descrição, ID ou IDG',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            SizedBox(height: 16),
            
            // Filtros por status
            BlocBuilder<TaskCubit, List<Map<String, dynamic>>>(
              builder: (context, tasks) {
                final cubit = context.read<TaskCubit>();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todas (${cubit.totalTasks})',
                        isSelected: cubit.currentFilter == TaskFilter.all,
                        onTap: () => cubit.setFilter(TaskFilter.all),
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: 'Ativas (${cubit.activeTasks})',
                        isSelected: cubit.currentFilter == TaskFilter.active,
                        onTap: () => cubit.setFilter(TaskFilter.active),
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: 'Concluídas (${cubit.completedTasks})',
                        isSelected: cubit.currentFilter == TaskFilter.completed,
                        onTap: () => cubit.setFilter(TaskFilter.completed),
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: 'Deletadas (${cubit.deletedTasks})',
                        isSelected: cubit.currentFilter == TaskFilter.deleted,
                        onTap: () => cubit.setFilter(TaskFilter.deleted),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            
            // Campo de nova tarefa
            TextField(
              controller: _taskDescriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição da Nova Tarefa',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _addTask(_taskDescriptionController.text);
                _taskDescriptionController.clear();
              },
              child: Text('Adicionar Tarefa (Testar Criação Idempotente)'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Minhas Tarefas:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                BlocBuilder<TaskCubit, List<Map<String, dynamic>>>(
                  builder: (context, tasks) {
                    final cubit = context.read<TaskCubit>();
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cubit.hasPagination 
                          ? '${cubit.currentPageStartItem}-${cubit.currentPageEndItem} de ${cubit.displayedItemsCount}'
                          : '${tasks.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: BlocBuilder<TaskCubit, List<Map<String, dynamic>>>(
                builder: (context, tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text('Nenhuma tarefa ainda.'));
                  }
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemExtent: 190,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final taskId = task['_id'];
                      final taskData = task['tasks'] ?? {};
                      final taskIdg = taskData['idg'] ?? 'N/A';
                      final description = taskData['description'] ?? 'Sem descrição';
                      final deletedAt = taskData['deletedAt'];
                      final isDeleted = deletedAt != null;
                      final isCompleted = taskData['completed'] == true && !isDeleted;
                      final isNew = !(isDeleted || isCompleted);

                      final theme = Theme.of(context);
                      Color? cardColor;
                      if (isDeleted) {
                        cardColor = theme.colorScheme.errorContainer.withAlpha((0.3 * 255).toInt());
                      } else if (isCompleted) {
                        cardColor = theme.colorScheme.surfaceContainerHighest;
                      } else if (isNew) {
                        cardColor = theme.colorScheme.secondaryContainer.withAlpha((0.3 * 255).toInt());
                      }

                      if (taskId == null) return const SizedBox.shrink();

                      return RepaintBoundary(
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
                                        description,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          fontStyle: isCompleted ? FontStyle.italic : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Checkbox(
                                      value: isCompleted,
                                      onChanged: isDeleted
                                          ? null
                                          : (bool? value) async {
                                              _atualizarBanco(taskId, isCompleted);
                                            },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: isDeleted ? Colors.red[900] : Colors.red),
                                      tooltip: isDeleted ? 'Deletar definitivamente' : 'Soft delete',
                                      onPressed: () async {
                                        if (isDeleted) {
                                          await _hardDeleteTask(taskId);
                                        } else {
                                          await _softDeleteTask(taskId);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _InfoChip(label: 'ID', value: taskId),
                                    _InfoChip(label: 'IDG', value: taskIdg),
                                    _InfoChip(label: 'Tipo', value: taskData['type'] ?? '-'),
                                    _InfoChip(label: 'Criada em', value: _formatTimestamp(taskData['createdAt'])),
                                    if (taskData['completedAt'] != null)
                                      _InfoChip(label: 'Completada em', value: _formatTimestamp(taskData['completedAt'])),
                                    if (taskData['deletedAt'] != null)
                                      _InfoChip(label: 'Deletada em', value: _formatTimestamp(taskData['deletedAt'])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<TaskCubit, List<Map<String, dynamic>>>(
              builder: (context, tasks) {
                final cubit = context.read<TaskCubit>();
                if (!cubit.hasPagination) return const SizedBox.shrink();
                return CustomPaginationBar(
                  currentPage: cubit.currentPage,
                  totalPages: cubit.totalPages,
                  totalResults: cubit.displayedItemsCount,
                  pageSize: cubit.itemsPerPage,
                  showingStart: cubit.currentPageStartItem,
                  showingEnd: cubit.currentPageEndItem,
                  onPrevious: cubit.hasPreviousPage ? cubit.previousPage : null,
                  onNext: cubit.hasNextPage ? cubit.nextPage : null,
                  onPageSelected: (page) => cubit.goToPage(page),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(dynamic ts) {
  if (ts == null) return '-';
  final date = DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.tryParse(ts.toString()) ?? 0);
  return '${date.day.toString().padLeft(2, '0')}/'
         '${date.month.toString().padLeft(2, '0')}/'
         '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
         '${date.minute.toString().padLeft(2, '0')}';
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class CustomPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalResults;
  final int pageSize;
  final int showingStart;
  final int showingEnd;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final void Function(int page)? onPageSelected;

  const CustomPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
    required this.pageSize,
    required this.showingStart,
    required this.showingEnd,
    this.onPrevious,
    this.onNext,
    this.onPageSelected,
  });

  List<Widget> _buildPageNumbers(BuildContext context) {
    List<Widget> widgets = [];
    int maxPagesToShow = 5;
    int startPage = (currentPage - 2).clamp(0, max(0, totalPages - maxPagesToShow));
    int endPage = min(startPage + maxPagesToShow, totalPages);

    if (startPage > 0) {
      widgets.add(_pageButton(context, 0));
      if (startPage > 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
    }

    for (int i = startPage; i < endPage; i++) {
      widgets.add(_pageButton(context, i));
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }
      widgets.add(_pageButton(context, totalPages - 1));
    }

    return widgets;
  }

  Widget _pageButton(BuildContext context, int page) {
    final bool isActive = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: isActive ? null : () => onPageSelected?.call(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Anterior',
            onPressed: currentPage > 0 ? onPrevious : null,
          ),
          // Números de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildPageNumbers(context),
          ),
          // Next
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próxima',
            onPressed: currentPage < totalPages - 1 ? onNext : null,
          ),
          // Info de resultados
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Mostrando $showingEnd de $totalResults resultados',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}