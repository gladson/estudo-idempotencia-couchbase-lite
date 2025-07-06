import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AddTask implements UseCase<String, Task> {
  final TaskRepository repository;

  AddTask(this.repository);

  @override
  Future<Result<String>> call(Task task) async {
    return await repository.addTask(task);
  }
}