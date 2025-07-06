import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<Task>>> getAllTasks() async {
    try {
      final taskMaps = await localDataSource.getAllTasks();
      // Converte a lista de Maps brutos em uma lista de entidades Task.
      final tasks = taskMaps.map((map) {
        return TaskModel.fromMap(map['data'], map['id']);
      }).toList();
      return Success(tasks);
    } on DataSourceException catch (e) {
      return Failure(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Result<String>> addTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final newId = await localDataSource.addTask(taskModel);
      return Success(newId);
    } on DataSourceException catch (e) {
      return Failure(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Result<void>> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      await localDataSource.updateTask(taskModel);
      return const Success(null);
    } on DataSourceException catch (e) {
      return Failure(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Result<void>> deleteTask(String taskId, {bool hardDelete = false}) async {
    try {
      await localDataSource.deleteTask(taskId, hardDelete: hardDelete);
      return const Success(null);
    } on DataSourceException catch (e) {
      return Failure(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Result<void>> addMultipleTasks(List<Task> tasks) async {
    try {
      final taskModels = tasks.map((task) => TaskModel.fromEntity(task)).toList();
      await localDataSource.addMultipleTasks(taskModels);
      return const Success(null);
    } on DataSourceException catch (e) {
      return Failure(DatabaseFailure(e.message));
    }
  }
}