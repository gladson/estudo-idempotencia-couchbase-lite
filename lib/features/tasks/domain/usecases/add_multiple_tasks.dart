import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AddMultipleTasks implements UseCase<void, List<Task>> {
  final TaskRepository repository;

  AddMultipleTasks(this.repository);

  @override
  Future<Result<void>> call(List<Task> tasks) async {
    return await repository.addMultipleTasks(tasks);
  }
}