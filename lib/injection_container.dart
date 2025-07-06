import 'package:get_it/get_it.dart';

import 'features/tasks/tasks_injection.dart';

// Instância do Service Locator
final sl = GetIt.instance;

Future<void> init() async {
  // ########################################
  // # Features
  // ########################################
  await initTasksFeature(sl);

  // Futuramente, você pode adicionar inicializadores de outras features aqui:
  //
  // await initAuthFeature(sl);
  // await initSettingsFeature(sl);
}