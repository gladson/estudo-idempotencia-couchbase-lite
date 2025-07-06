import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/task_repository.dart';

class DeleteTask implements UseCase<void, DeleteTaskParams> {
  final TaskRepository repository;

  DeleteTask(this.repository);

  @override
  Future<Result<void>> call(DeleteTaskParams params) async {
    return await repository.deleteTask(params.taskId, hardDelete: params.hardDelete);
  }
}

class DeleteTaskParams extends Equatable {
  final String taskId;
  final bool hardDelete;

  const DeleteTaskParams({required this.taskId, this.hardDelete = false});

  @override
  List<Object> get props => [taskId, hardDelete];
}