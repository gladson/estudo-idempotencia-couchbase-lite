import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetAllTasks implements UseCase<List<Task>, NoParams> {
  final TaskRepository repository;

  GetAllTasks(this.repository);

  @override
  Future<Result<List<Task>>> call(NoParams params) async {
    return await repository.getAllTasks();
  }
}