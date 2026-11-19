import 'package:manage_aura/model/enums.dart';
import 'package:manage_aura/model/product.dart';
import 'package:manage_aura/model/shop.dart';
import 'package:manage_aura/model/supplier.dart';
import 'package:manage_aura/service/stock_service.dart';

void main() {
  final shop = Shop('Socheata');
  final service = StockService(shop: shop);

  _title('1. Setup');
  final apple = service.addSupplier(
    Supplier(id: 'S1', name: 'Apple Cambodia', phone: '012 345 678'),
  );

  service.addProduct(Product(
      id: '123', name: 'iPhone 7', sku: 'iph1237', price: 49,
      category: 'Phone', supplier: apple));
  service.addProduct(Product(
      id: '124', name: 'iPhone 8', sku: 'iph1238', price: 99,
      category: 'Phone', supplier: apple));
  service.addProduct(Product(
      id: '125', name: 'AirPods', sku: 'air001', price: 129,
      category: 'Accessory', lowStockThreshold: 3));

  print('Shop "${shop.name}" has ${shop.products.length} products, '
      '${shop.suppliers.length} supplier.');

  _title('2. Stock movements');
  service.stockIn('123', 20, supplierId: 'S1', note: 'Initial delivery');
  service.stockIn('124', 4, supplierId: 'S1');
  service.stockIn('125', 2);
  service.stockOut('123', 5, note: 'Sold to customer');
  service.adjustStock('125', 6, note: 'Recount after inventory check');

  for (final p in shop.products) {
    print('${p.name.padRight(10)} qty: ${p.quantity.toString().padLeft(3)}  '
        'status: ${p.status.name}');
  }

  _title('3. Business rules');
  _tryIt('Sell more than on hand', () => service.stockOut('124', 99));
  _tryIt('Stock in with qty 0', () => service.stockIn('123', 0));
  _tryIt('Duplicate SKU', () => service.addProduct(
      Product(id: '999', name: 'Clone', sku: 'iph1237', price: 1)));
  _tryIt('Unknown product', () => service.getProduct('nope'));

  _title('4. Search & filter');
  print('Search "iphone":  ${service.searchProducts(query: 'iphone')}');
  print('Low stock only:   '
      '${service.searchProducts(status: StockStatus.lowStock)}');
  print('Chip counts:      ${service.statusCounts()}');

  _title('5. Transactions (today)');
  for (final t in service.getTransactions(period: TransactionPeriod.today)) {
    final sign = t.delta >= 0 ? '+' : '';
    print('${t.id}  ${t.type.name.padRight(8)} product ${t.productId}  '
        '$sign${t.delta}  ${t.note}');
  }
  final totals = service.transactionTotals(TransactionPeriod.today);
  print('Totals: ${totals.map((k, v) => MapEntry(k.name, v))}');

  _title('6. Dashboard');
  final d = service.dashboard();
  print('Total stock value : \$${d.totalStockValue.toStringAsFixed(2)}');
  print('Products          : ${d.totalProducts} in ${d.totalCategories} categories');
  print('Transactions today: ${d.todayTransactions}');
  print('Low / Out of stock: ${d.lowStockCount} / ${d.outOfStockCount}');
  print('Needs restock     : ${service.predictOutOfStock()}');
}

void _title(String text) => print('\n=== $text ===');

void _tryIt(String label, void Function() action) {
  try {
    action();
    print('$label -> OK (unexpected)');
  } on StateError catch (e) {
    print('$label -> blocked: ${e.message}');
  } on ArgumentError catch (e) {
    print('$label -> blocked: ${e.message}');
  }
}