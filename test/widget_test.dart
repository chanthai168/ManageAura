import 'package:flutter_test/flutter_test.dart';
import 'package:manage_aura/model/enums.dart';
import 'package:manage_aura/model/product.dart';
import 'package:manage_aura/model/shop.dart';
import 'package:manage_aura/model/stock_transaction.dart';
import 'package:manage_aura/model/supplier.dart';
import 'package:manage_aura/service/stock_service.dart';

void main() {
  group('Model tests', () {
    test('Shop, supplier and product validate required values', () {
      expect(() => Shop(''), throwsArgumentError);
      expect(() => Supplier(id: 'S1', name: ''), throwsArgumentError);
      expect(
        () => Product(id: 'P1', name: '', sku: 'SKU1', price: 10),
        throwsArgumentError,
      );
    });

    test('Product status and stock value are calculated from quantity', () {
      final product = Product(
        id: 'P1',
        name: 'Phone',
        sku: 'SKU1',
        price: 25,
        quantity: 10,
        lowStockThreshold: 5,
      );

      expect(product.status, StockStatus.inStock);
      expect(product.stockValue, 250);

      product.quantity = 5;
      expect(product.status, StockStatus.lowStock);

      product.quantity = 0;
      expect(product.status, StockStatus.outOfStock);
    });

    test('Negative prices and quantities are rejected', () {
      expect(
        () => Product(id: 'P1', name: 'Phone', sku: 'SKU1', price: -1),
        throwsArgumentError,
      );
      expect(
        () => Product(
          id: 'P1',
          name: 'Phone',
          sku: 'SKU1',
          price: 10,
          quantity: -1,
        ),
        throwsArgumentError,
      );
    });

    test('Stock transaction rejects negative quantity', () {
      expect(
        () => StockTransaction(
          id: 'T1',
          productId: 'P1',
          type: TransactionType.stockIn,
          quantity: -1,
          delta: -1,
          date: DateTime(2026, 6, 17),
        ),
        throwsArgumentError,
      );
    });
  });

  group('StockService tests', () {
    late Shop shop;
    late StockService service;
    late Product phone;

    setUp(() {
      final fixedNow = DateTime(2026, 6, 17, 12);
      shop = Shop('Test Shop');
      service = StockService(shop: shop, now: () => fixedNow);

      service.addSupplier(Supplier(id: 'S1', name: 'Phone Supplier'));
      phone = Product(
        id: 'P1',
        name: 'Phone',
        sku: 'SKU1',
        price: 25,
        quantity: 10,
        lowStockThreshold: 5,
        category: 'Mobile',
      );
      service.addProduct(phone);
    });

    test('Duplicate suppliers and products are rejected', () {
      expect(
        () => service.addSupplier(Supplier(id: 'S1', name: 'Duplicate')),
        throwsStateError,
      );
      expect(
        () => service.addProduct(
          Product(id: 'P2', name: 'Other', sku: 'SKU1', price: 10),
        ),
        throwsStateError,
      );
    });

    test('Searches use name or SKU and support status filtering', () {
      final tablet = service.addProduct(
        Product(
          id: 'P2',
          name: 'Tablet',
          sku: 'TAB2',
          price: 100,
          quantity: 2,
          lowStockThreshold: 5,
        ),
      );

      expect(service.searchProducts(query: 'phone').single, same(phone));
      expect(service.searchProducts(query: 'tab').single, same(tablet));
      expect(
        service.searchProducts(status: StockStatus.lowStock).single,
        same(tablet),
      );
    });

    test('Stock in, stock out and adjust update quantity and history', () {
      final stockIn = service.stockIn(
        'P1',
        5,
        supplierId: 'S1',
        note: 'Received',
      );
      expect(phone.quantity, 15);
      expect(stockIn.delta, 5);

      final stockOut = service.stockOut('P1', 3, note: 'Sale');
      expect(phone.quantity, 12);
      expect(stockOut.delta, -3);

      final adjustment = service.adjustStock('P1', 10);
      expect(phone.quantity, 10);
      expect(adjustment.delta, -2);
      expect(phone.history.length, 3);
      expect(shop.transactions.length, 3);
    });

    test('Stock out rejects overselling and dashboard reports totals', () {
      expect(() => service.stockOut('P1', 11), throwsStateError);

      final transaction = service.stockIn('P1', 2);
      final summary = service.dashboard();

      expect(transaction.type, TransactionType.stockIn);
      expect(summary.totalStockValue, 300);
      expect(summary.todayTransactions, 1);
      expect(summary.totalProducts, 1);
      expect(summary.lowStockCount, 0);
      expect(summary.outOfStockCount, 0);
    });

    test('Status counts and predictions identify stock levels', () {
      service.addProduct(
        Product(
          id: 'P2',
          name: 'Tablet',
          sku: 'TAB2',
          price: 100,
          quantity: 2,
          lowStockThreshold: 5,
        ),
      );
      service.addProduct(
        Product(id: 'P3', name: 'Case', sku: 'CASE3', price: 10, quantity: 0),
      );

      expect(service.statusCounts(), {'all': 3, 'low': 1, 'out': 1});
      expect(service.predictOutOfStock().map((product) => product.id).toSet(), {
        'P2',
        'P3',
      });
    });

    test('Stock in and stock out record supplier and transaction details', () {
      final stockIn = service.stockIn(
        'P1',
        5,
        supplierId: 'S1',
        note: 'Morning delivery',
      );
      final stockOut = service.stockOut('P1', 3, note: 'Customer sale');

      expect(stockIn.type, TransactionType.stockIn);
      expect(stockIn.quantity, 5);
      expect(stockIn.delta, 5);
      expect(stockIn.supplierId, 'S1');
      expect(stockIn.note, 'Morning delivery');

      expect(stockOut.type, TransactionType.stockOut);
      expect(stockOut.quantity, 3);
      expect(stockOut.delta, -3);
      expect(stockOut.supplierId, isNull);
      expect(stockOut.note, 'Customer sale');

      expect(phone.history, contains(stockIn));
      expect(phone.history, contains(stockOut));
      expect(shop.transactions, contains(stockIn));
      expect(shop.transactions, contains(stockOut));
    });

    test('Invalid stock operations reject zero and missing records', () {
      expect(() => service.stockIn('P1', 0), throwsArgumentError);
      expect(() => service.stockOut('P1', 0), throwsArgumentError);
      expect(() => service.adjustStock('P1', -1), throwsArgumentError);
      expect(() => service.stockIn('missing', 5), throwsStateError);
      expect(
        () => service.stockIn('P1', 5, supplierId: 'missing'),
        throwsStateError,
      );
    });

    test('Transactions are filterable by type and period', () {
      service.stockIn('P1', 2);
      service.stockOut('P1', 1);

      final stockInTransactions = service.getTransactions(
        type: TransactionType.stockIn,
      );
      final stockOutTransactions = service.getTransactions(
        type: TransactionType.stockOut,
      );
      final todayTransactions = service.getTransactions(
        period: TransactionPeriod.today,
      );

      expect(stockInTransactions, hasLength(1));
      expect(stockOutTransactions, hasLength(1));
      expect(todayTransactions, hasLength(2));

      final totals = service.transactionTotals(TransactionPeriod.today);
      expect(totals[TransactionType.stockIn], 1);
      expect(totals[TransactionType.stockOut], 1);
      expect(totals[TransactionType.adjust], 0);
    });

    test('Get product throws when an id does not exist', () {
      expect(() => service.getProduct('missing'), throwsStateError);
      expect(service.getProduct('P1'), same(phone));
    });
  });
}
