import 'product.dart';
import 'stock_transaction.dart';
import 'supplier.dart';

/// The shop owns its products, suppliers and transactions (composition).
class Shop {
  final String name;
  final List<Product> products = [];
  final List<Supplier> suppliers = [];
  final List<StockTransaction> transactions = [];

  Shop(this.name) {
    if (name.trim().isEmpty) throw ArgumentError('Shop name cannot be empty');
  }
}
