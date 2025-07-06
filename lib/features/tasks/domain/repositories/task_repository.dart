import '../../../../core/utils/result.dart';
import '../entities/task.dart';

// O "Contrato" que a camada de dados deverá implementar.
// A camada de domínio só conhece este contrato, não a implementação real (Couchbase, API, etc.).
abstract class TaskRepository {
  Future<Result<List<Task>>> getAllTasks();
  Future<Result<String>> addTask(Task task);
  Future<Result<void>> updateTask(Task task);
  Future<Result<void>> deleteTask(String taskId, {bool hardDelete = false});
  Future<Result<void>> addMultipleTasks(List<Task> tasks);
}