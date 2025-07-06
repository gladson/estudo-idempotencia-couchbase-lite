import 'package:get_it/get_it.dart';

import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/domain/usecases/add_multiple_tasks.dart';
import 'features/tasks/domain/usecases/delete_task.dart';
import 'features/tasks/domain/usecases/get_all_tasks.dart';
import 'features/tasks/domain/usecases/update_task.dart';
import 'features/tasks/presentation/cubit/task_cubit.dart';

// Instância do Service Locator
final sl = GetIt.instance;

Future<void> init() async {
  // ########################################
  // # Features - Tasks
  // ########################################

  // Cubit
  sl.registerFactory(() => TaskCubit(
        getAllTasksUseCase: sl(),
        addTaskUseCase: sl(),
        updateTaskUseCase: sl(),
        deleteTaskUseCase: sl(),
        addMultipleTasksUseCase: sl(),
      ));

  // Casos de Uso (Use Cases)
  // Registramos como 'factory' porque eles são classes pequenas e sem estado.
  // Uma nova instância será criada toda vez que forem solicitados.
  sl.registerFactory(() => GetAllTasks(sl()));
  sl.registerFactory(() => AddTask(sl()));
  sl.registerFactory(() => UpdateTask(sl()));
  sl.registerFactory(() => DeleteTask(sl()));
  sl.registerFactory(() => AddMultipleTasks(sl()));

  // Repositório (Repository)
  // Registramos como 'lazySingleton' porque só precisamos de uma instância
  // do repositório em todo o app. Será criado apenas na primeira vez que for solicitado.
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(localDataSource: sl()),
  );

  // Fonte de Dados (Data Source)
  // Registramos como um 'singleton' e o inicializamos imediatamente,
  // garantindo que o banco de dados esteja pronto antes do app iniciar.
  final dataSource = TaskLocalDataSourceImpl();
  await dataSource.initDb();
  sl.registerSingleton<TaskLocalDataSource>(dataSource);
}