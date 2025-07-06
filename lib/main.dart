import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/tasks/presentation/pages/task_page.dart';
import 'injection_container.dart' as di; // Importamos com um alias 'di'

Future<void> main() async {
  // Garante que os bindings do Flutter foram inicializados antes de rodar código assíncrono.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Couchbase Lite para a plataforma.
  await CouchbaseLiteFlutter.init();

  // Inicializa nosso contêiner de injeção de dependência.
  await di.init();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<TaskCubit>()..loadTasks(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Idempotência com Couchbase Lite',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const TaskPage(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.orange,
        brightness: brightness,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: brightness == Brightness.light
                ? Colors.grey.shade300
                : Colors.grey.shade800,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}