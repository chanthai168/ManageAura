import '../model/enums.dart';
import '../model/product.dart';
import '../model/shop.dart';
import '../model/stock_transaction.dart';
import '../model/supplier.dart';
import '../model/dashboard_summary.dart';


class StockService {
  final Shop shop;
  final DateTime Function() _now;
  int _txCounter = 0;

  StockService({required this.shop, DateTime Function()? now}) : _now = now ?? DateTime.now;

  Supplier addSupplier(Supplier supplier) {
    if (shop.suppliers.any((s) => s.id == supplier.id)) {
      throw StateError('Supplier ${supplier.id} already exists');
    }
    shop.suppliers.add(supplier);
    return supplier;
  }

  Product addProduct(Product product) {
    if (shop.products.any((p) => p.sku == product.sku || p.id == product.id)) {
      throw StateError('Product with SKU ${product.sku} already exists');
    }
    shop.products.add(product);
    return product;
  }

  Product getProduct(String productId) {
    return shop.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Product $productId not found'),
    );
  }

  List<Product> searchProducts({String query = '', StockStatus? status}) {
    final q = query.trim().toLowerCase();
    final result = shop.products.where((p) {
      final matches = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
      return matches && (status == null || p.status == status);
    }).toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Map<String, int> statusCounts() => {
        'all': shop.products.length,
        'low': shop.products.where((p) => p.status == StockStatus.lowStock).length,
        'out': shop.products.where((p) => p.status == StockStatus.outOfStock).length,
      };


  StockTransaction stockIn(String productId, int quantity,
      {String? supplierId, String note = ''}) {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than 0');
    final product = getProduct(productId);
    if (supplierId != null) _requireSupplier(supplierId);
    product.quantity += quantity;
    return _record(product, TransactionType.stockIn, quantity, quantity, note, supplierId);
  }

  StockTransaction stockOut(String productId, int quantity, {String note = ''}) {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than 0');
    final product = getProduct(productId);
    if (quantity > product.quantity) {
      throw StateError(
          'Insufficient stock: requested $quantity, on hand ${product.quantity}');
    }
    product.quantity -= quantity;
    return _record(product, TransactionType.stockOut, quantity, -quantity, note, null);
  }

  StockTransaction adjustStock(String productId, int newQuantity, {String note = ''}) {
    if (newQuantity < 0) throw ArgumentError('Quantity cannot be negative');
    final product = getProduct(productId);
    final diff = newQuantity - product.quantity;
    product.quantity = newQuantity;
    return _record(product, TransactionType.adjust, diff.abs(), diff, note, null);
  }

  List<StockTransaction> getTransactions(
      {TransactionType? type, TransactionPeriod? period}) {
    final now = _now();
    final result = shop.transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (period != null && !_inPeriod(t.date, now, period)) return false;
      return true;
    }).toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Map<TransactionType, int> transactionTotals(TransactionPeriod period) {
    final list = getTransactions(period: period);
    return {
      for (final type in TransactionType.values)
        type: list.where((t) => t.type == type).length,
    };
  }

  DashboardSummary dashboard() {
    final now = _now();
    return DashboardSummary(
      totalStockValue: shop.products.fold(0.0, (sum, p) => sum + p.stockValue),
      todayTransactions: shop.transactions
          .where((t) => _inPeriod(t.date, now, TransactionPeriod.today))
          .length,
      totalProducts: shop.products.length,
      totalCategories: shop.products.map((p) => p.category).toSet().length,
      lowStockCount: shop.products.where((p) => p.status == StockStatus.lowStock).length,
      outOfStockCount:
          shop.products.where((p) => p.status == StockStatus.outOfStock).length,
    );
  }

  List<Product> predictOutOfStock() =>
      shop.products.where((p) => p.status != StockStatus.inStock).toList();

  void _requireSupplier(String id) {
    if (!shop.suppliers.any((s) => s.id == id)) {
      throw StateError('Supplier $id not found');
    }
  }

  StockTransaction _record(Product product, TransactionType type, int quantity,
    int delta, String note, String? supplierId) {
    final tx = StockTransaction(
      id: 'T${++_txCounter}',
      productId: product.id,
      type: type,
      quantity: quantity,
      delta: delta,
      date: _now(),
      note: note,
      supplierId: supplierId,
    );
    product.history.add(tx);
    shop.transactions.add(tx);
    return tx;
  }

  bool _inPeriod(DateTime date, DateTime now, TransactionPeriod period) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (period) {
      case TransactionPeriod.today:

        // 00:00:00 -> 23:59:99
        return !date.isBefore(startOfToday) &&
            date.isBefore(startOfToday.add(const Duration(days: 1)));

      case TransactionPeriod.thisWeek:

        // from monday
        final start = startOfToday.subtract(Duration(days: now.weekday - 1));
        return !date.isBefore(start) && !date.isAfter(now);
      case TransactionPeriod.thisMonth:

        // current year , current month until now 
        return date.year == now.year && date.month == now.month && !date.isAfter(now);
    }
  }
}
