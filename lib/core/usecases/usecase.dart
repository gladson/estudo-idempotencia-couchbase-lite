import 'package:equatable/equatable.dart';

import '../utils/result.dart';

// Contrato para todos os Casos de Uso.
abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

// Classe auxiliar para Casos de Uso que não recebem parâmetros.
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}