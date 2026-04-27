class FinancialHistory {
  final String id;
  final String recordId;
  final DateTime date;
  final String action;
  final String responsible;
  final String details;

  FinancialHistory({
    required this.id,
    required this.recordId,
    required this.date,
    required this.action,
    required this.responsible,
    required this.details,
  });
}
