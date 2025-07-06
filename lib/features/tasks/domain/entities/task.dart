import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id; // ID do documento do Couchbase (_id)
  final String idg; // ID de idempotência
  final String description;
  final bool completed;
  final int createdAt;
  final int? completedAt;
  final int? deletedAt;
  final int? updatedAt;

  const Task({
    required this.id,
    required this.idg,
    required this.description,
    required this.completed,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
    this.updatedAt,
  });

  // Helper para saber se a tarefa está ativa (não deletada)
  bool get isDeleted => deletedAt != null;

  // Helper para criar uma cópia do objeto com alguns campos alterados.
  // Muito útil para o gerenciamento de estado.
  Task copyWith({
    bool? completed,
    int? completedAt,
    int? deletedAt,
    int? updatedAt,
  }) {
    return Task(
      id: id,
      idg: idg,
      description: description,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: completedAt, // Note que não usamos ?? aqui para permitir nulo
      deletedAt: deletedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, idg, description, completed, createdAt, completedAt, deletedAt, updatedAt];
}