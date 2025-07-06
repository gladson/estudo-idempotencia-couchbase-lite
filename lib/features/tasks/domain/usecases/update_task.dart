import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTask implements UseCase<void, Task> {
  final TaskRepository repository;

  UpdateTask(this.repository);

  @override
  Future<Result<void>> call(Task task) async {
    return await repository.updateTask(task);
  }
}