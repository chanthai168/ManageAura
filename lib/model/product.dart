import 'enums.dart';
import 'stock_transaction.dart';
import 'supplier.dart';

class Product {
  final String id;
  String name;
  final String sku;
  double price;
  int quantity;
  int lowStockThreshold;
  String description;
  String category;

  /// Aggregation: a product may be bought from a supplier, but the supplier
  /// exists independently of the product.
  Supplier? supplier;

  /// Composition: the history belongs to the product and is created with it.
  final List<StockTransaction> history = [];

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.description = '',
    this.category = 'General',
    this.supplier,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Product name cannot be empty');
    if (sku.trim().isEmpty) throw ArgumentError('SKU cannot be empty');
    if (price < 0) throw ArgumentError('Price cannot be negative');
    if (quantity < 0) throw ArgumentError('Quantity cannot be negative');
  }

  /// Badge shown on the Product screen.
  StockStatus get status {
    if (quantity == 0) return StockStatus.outOfStock;
    if (quantity <= lowStockThreshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  double get stockValue => price * quantity;

  @override
  String toString() => 'Product($sku, $name, qty: $quantity)';
}
