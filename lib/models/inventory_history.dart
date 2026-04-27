class InventoryHistory {
  final String id;
  final String itemId;
  final DateTime date;
  final String action;
  final int? oldQuantity;
  final int? newQuantity;
  final String? details;

  InventoryHistory({
    required this.id,
    required this.itemId,
    required this.date,
    required this.action,
    this.oldQuantity,
    this.newQuantity,
    this.details,
  });
}
