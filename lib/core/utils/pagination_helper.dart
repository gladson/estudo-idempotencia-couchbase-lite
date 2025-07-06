/// Uma classe auxiliar para gerenciar o estado da paginação.
///
/// Esta classe foi projetada para ser usada em uma solução de gerenciamento de estado (como um Cubit ou Bloc)
/// para lidar com a lógica de divisão de uma lista grande em páginas.
///
/// Observação: Este auxiliar pressupõe que a lista completa de itens esteja disponível na memória.
/// Para conjuntos de dados muito grandes, a paginação deve ser tratada no nível da fonte de dados
/// (por exemplo, na consulta ao banco de dados) para melhor desempenho.
class PaginationHelper {
  final int totalItems;
  final int itemsPerPage;

  int _currentPage = 0;

  PaginationHelper({
    required this.totalItems,
    this.itemsPerPage = 100,
  });

  // Getters
  int get currentPage => _currentPage;
  int get totalPages => totalItems == 0 ? 1 : (totalItems / itemsPerPage).ceil();
  bool get hasPagination => totalItems > itemsPerPage;
  bool get hasNextPage => _currentPage < totalPages - 1;
  bool get hasPreviousPage => _currentPage > 0;

  /// Calculates the start index for the current page's sublist.
  int get startIndex => _currentPage * itemsPerPage;

  /// Calculates the end index for the current page's sublist.
  int get endIndex => (startIndex + itemsPerPage) > totalItems
      ? totalItems
      : (startIndex + itemsPerPage);

  // Methods

  /// Moves to the next page if possible. Returns `true` if the page changed.
  bool nextPage() {
    if (hasNextPage) {
      _currentPage++;
      return true;
    }
    return false;
  }

  /// Moves to the previous page if possible. Returns `true` if the page changed.
  bool previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      return true;
    }
    return false;
  }

  /// Jumps to a specific page. Returns `true` if the page changed.
  bool goToPage(int page) {
    if (page >= 0 && page < totalPages && page != _currentPage) {
      _currentPage = page;
      return true;
    }
    return false;
  }

  /// Resets the pagination to the first page.
  void reset() {
    _currentPage = 0;
  }
}