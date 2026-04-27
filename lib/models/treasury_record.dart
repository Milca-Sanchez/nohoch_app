class TreasuryRecord {
  final String id;
  final String concept;
  final double amount;
  final DateTime date;
  final String description;
  final String responsible;
  final String? notes;
  final bool isIncome;

  TreasuryRecord({
    required this.id,
    required this.concept,
    required this.amount,
    required this.date,
    required this.description,
    required this.responsible,
    this.notes,
    required this.isIncome,
  });

  TreasuryRecord copyWith({
    String? id,
    String? concept,
    double? amount,
    DateTime? date,
    String? description,
    String? responsible,
    String? notes,
    bool? isIncome,
  }) {
    return TreasuryRecord(
      id: id ?? this.id,
      concept: concept ?? this.concept,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      responsible: responsible ?? this.responsible,
      notes: notes ?? this.notes,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
