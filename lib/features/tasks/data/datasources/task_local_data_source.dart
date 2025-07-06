import 'dart:async';
// Usamos um alias para evitar conflitos de nome e `cbl_flutter` para a inicialização.
import 'package:cbl/cbl.dart' as cbl;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/task_model.dart';

/// Exceção personalizada para erros na fonte de dados.
class DataSourceException implements Exception {
  final String message;
  DataSourceException(this.message);
}

/// Contrato para a fonte de dados local das tarefas.
abstract class TaskLocalDataSource {
  Future<void> initDb();
  Future<List<Map<String, dynamic>>> getAllTasks();
  Future<String> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId, {required bool hardDelete});
  Future<void> addMultipleTasks(List<TaskModel> tasks);
  Future<void> closeDb();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  cbl.Database? _database;
  cbl.Collection? _collection;

  static const String _dbName = 'tasks_idempotence_db';
  static const String _collectionName = 'tasks';

  Future<cbl.Collection> get collection async {
    if (_database == null) {
      await initDb();
    }
    // A coleção é garantida como não nula se o banco de dados estiver aberto.
    return _collection!;
  }

  @override
  Future<void> initDb() async {
    try {
      // O `CouchbaseLiteFlutter.init()` deve ser chamado no main.dart.
      // Usamos getApplicationDocumentsDirectory para o caminho correto no mobile.
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'db');

      _database = await cbl.Database.openAsync(
        _dbName,
        cbl.DatabaseConfiguration(directory: dbPath),
      );

      _collection = await _database!.createCollection(_collectionName);

      // Cria um índice para a chave de idempotência para otimizar buscas.
      await _collection!.createIndex(
        'idg-index',
        cbl.ValueIndex([cbl.ValueIndexItem.property('idg')]),
      );
    } catch (e) {
      throw DataSourceException('Falha ao inicializar o banco de dados: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = _database;
    if (db == null) throw DataSourceException("Banco de dados não inicializado.");

    // Usamos N1QL para a query, que é poderoso e legível.
    // `SELECT *` retorna um mapa onde a chave é o nome da coleção.
    final query = await db.createQuery('''
      SELECT meta().id as _id, *
      FROM $_collectionName
      WHERE type = 'task'
      ORDER BY createdAt ASC
    ''');

    final resultSet = await query.execute();
    final results = await resultSet.allResults();

    return results.map((result) {
      final plainMap = result.toPlainMap();
      // O mapa do resultado é `{"_id": "...", "tasks": {"type": "task", ...}}`
      // Reestruturamos para o formato que o repositório espera.
      return {
        'id': plainMap['_id'],
        'data': plainMap[_collectionName] as Map<String, dynamic>,
      };
    }).toList();
  }

  @override
  Future<String> addTask(TaskModel task) async {
    final col = await collection;
    // Deixamos o Couchbase gerar o ID do documento automaticamente.
    final doc = cbl.MutableDocument(task.toMap());
    await col.saveDocument(doc);
    return doc.id;
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final col = await collection;
    final doc = await col.document(task.id);
    if (doc != null) {
      final mutableDoc = doc.toMutable();
      mutableDoc.setData(task.toMap());
      await col.saveDocument(mutableDoc);
    } else {
      throw DataSourceException('Tarefa com id ${task.id} não encontrada para atualização.');
    }
  }

  @override
  Future<void> deleteTask(String taskId, {required bool hardDelete}) async {
    final col = await collection;
    final doc = await col.document(taskId);
    if (doc != null) {
      if (hardDelete) {
        await col.deleteDocument(doc);
      } else {
        // Lógica de Soft Delete: atualiza os campos necessários.
        final mutableDoc = doc.toMutable();
        final now = DateTime.now().millisecondsSinceEpoch;
        mutableDoc.setValue(now, key: 'deletedAt');
        mutableDoc.setValue(now, key: 'updatedAt');
        await col.saveDocument(mutableDoc);
      }
    }
  }

  @override
  Future<void> addMultipleTasks(List<TaskModel> tasks) async {
    final col = await collection;
    // Usamos o inBatch do banco de dados para operações em massa.
    await _database!.inBatch(() async {
      for (final task in tasks) {
        // Deixamos o Couchbase gerar o ID do documento automaticamente.
        final doc = cbl.MutableDocument(task.toMap());
        await col.saveDocument(doc);
      }
    });
  }

  @override
  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}