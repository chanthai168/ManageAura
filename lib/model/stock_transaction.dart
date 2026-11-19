import 'enums.dart';

class StockTransaction {
  final String id;
  final String productId;
  final TransactionType type;
  final int quantity;
  final int delta;
  final DateTime date;
  final String note;
  final String? supplierId;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.delta,
    required this.date,
    this.note = '',
    this.supplierId,
  }) {
    if (quantity < 0) throw ArgumentError('Quantity cannot be negative');
  }

  @override
  String toString() => 'StockTransaction($id, $productId, $type, $delta)';
}
