import 'package:equatable/equatable.dart';

abstract class AppFailure extends Equatable {
  const AppFailure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

// Falha específica para erros de banco de dados
class DatabaseFailure extends AppFailure {
  final String message;

  const DatabaseFailure(this.message);

  @override
  List<Object> get props => [message];
}