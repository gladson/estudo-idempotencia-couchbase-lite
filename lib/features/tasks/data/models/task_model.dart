import '../../domain/entities/task.dart';

// TaskModel é a implementação da entidade Task na camada de dados.
// Ele estende a entidade e adiciona a lógica de serialização/deserialização.
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.idg,
    required super.description,
    required super.completed,
    required super.createdAt,
    super.completedAt,
    super.deletedAt,
    super.updatedAt,
  });

  // Converte um Map (vindo do Couchbase) para um objeto TaskModel.
  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    return TaskModel(
      id: docId,
      idg: map['idg'] as String,
      description: map['description'] as String,
      completed: map['completed'] as bool,
      createdAt: map['createdAt'] as int,
      completedAt: map['completedAt'] as int?,
      deletedAt: map['deletedAt'] as int?,
      updatedAt: map['updatedAt'] as int?,
    );
  }

  // Converte um objeto TaskModel para um Map para ser salvo no Couchbase.
  Map<String, dynamic> toMap() {
    return {
      'type': 'task', // Mantendo o tipo para futuras queries
      'idg': idg,
      'description': description,
      'completed': completed,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'deletedAt': deletedAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper para converter uma entidade Task em um TaskModel
  factory TaskModel.fromEntity(Task entity) {
    return TaskModel(
      id: entity.id,
      idg: entity.idg,
      description: entity.description,
      completed: entity.completed,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      deletedAt: entity.deletedAt,
      updatedAt: entity.updatedAt,
    );
  }
}