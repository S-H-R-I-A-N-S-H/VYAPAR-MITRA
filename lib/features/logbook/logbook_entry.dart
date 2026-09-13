class LogbookEntry {
  final int? id;
  final String itemDescription;
  final double quantity;
  final String unit;
  final double amountRupees;
  final String? category;
  final List<String>? tags;
  final DateTime createdAt;
  bool synced;

  LogbookEntry({
    this.id,
    required this.itemDescription,
    required this.quantity,
    required this.unit,
    required this.amountRupees,
    this.category,
    this.tags,
    DateTime? createdAt,
    this.synced = false,
  }) : createdAt = createdAt ?? DateTime.now();
}
