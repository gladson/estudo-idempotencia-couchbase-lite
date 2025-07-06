import 'package:get_it/get_it.dart';

import 'data/datasources/task_local_data_source.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';
import 'domain/usecases/add_multiple_tasks.dart';
import 'domain/usecases/add_task.dart';
import 'domain/usecases/delete_task.dart';
import 'domain/usecases/get_all_tasks.dart';
import 'domain/usecases/update_task.dart';
import 'presentation/cubit/task_cubit.dart';

/// Inicializa as dependências da feature de Tarefas.
Future<void> initTasksFeature(GetIt sl) async {
  // Cubit
  sl.registerFactory(() => TaskCubit(
        getAllTasksUseCase: sl(),
        addTaskUseCase: sl(),
        updateTaskUseCase: sl(),
        deleteTaskUseCase: sl(),
        addMultipleTasksUseCase: sl(),
      ));

  // Casos de Uso (Use Cases)
  sl.registerFactory(() => GetAllTasks(sl()));
  sl.registerFactory(() => AddTask(sl()));
  sl.registerFactory(() => UpdateTask(sl()));
  sl.registerFactory(() => DeleteTask(sl()));
  sl.registerFactory(() => AddMultipleTasks(sl()));

  // Repositório (Repository)
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(localDataSource: sl()),
  );

  // Fonte de Dados (Data Source)
  final dataSource = TaskLocalDataSourceImpl();
  await dataSource.initDb();
  sl.registerSingleton<TaskLocalDataSource>(dataSource);
}