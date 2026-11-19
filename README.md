# 📦 Manage Aura

**A clean, console-first stock manager for small shops, written in Dart.**

Track products, suppliers and every stock movement, with the business rules built in so your numbers never go wrong. No UI and no database, just a tidy domain model and service layer that is easy to read, test and plug into a Flutter app later.

---

## ✨ Features

- **Products:** SKU, price, category, low-stock threshold and automatic status badges (`inStock` / `lowStock` / `outOfStock`)
- **Suppliers:** keep them independent of products and link them to deliveries
- **Stock movements:** stock in, stock out and manual adjustments, each logged as a transaction
- **Smart rules:** unique SKUs, no overselling, no negative quantities
- **Search and filter:** by name or SKU, with status chips (All / Low / Out)
- **Transaction history:** filter by type (in / out / adjust) and period (today / this week / this month)
- **Dashboard:** total stock value, product and category counts, today's activity, low and out-of-stock counts
- **Restock prediction:** lists products at or below their threshold

---

## 🗂 Project structure

```
lib/
├── main.dart                  # Demo script
├── model/
│   ├── enums.dart             # TransactionType, StockStatus, TransactionPeriod
│   ├── product.dart           # Product + stock status logic
│   ├── supplier.dart          # Supplier
│   ├── shop.dart              # Shop (owns products, suppliers, transactions)
│   ├── stock_transaction.dart # One stock movement
│   └── dashboard_summary.dart # Home-screen numbers
└── service/
    └── stock_service.dart     # All business operations
```

### Design notes

| Relationship | Type | Meaning |
|---|---|---|
| Shop → Products / Suppliers / Transactions | Composition | The shop owns them |
| Product → Transaction history | Composition | History is created with the product |
| Product → Supplier | Aggregation | A supplier exists without the product |

---

## 🚀 Quick start

```bash
dart pub get
dart run lib/main.dart
```

Requires the Dart SDK. The package name is `manage_aura`.

---

## 🧪 Usage

```dart
final shop = Shop('Socheata');
final service = StockService(shop: shop);

service.addSupplier(Supplier(id: 'S1', name: 'Apple Cambodia'));
service.addProduct(Product(id: '123', name: 'iPhone 7', sku: 'iph1237', price: 49));

service.stockIn('123', 20, supplierId: 'S1', note: 'Initial delivery');
service.stockOut('123', 5, note: 'Sold to customer');
service.adjustStock('123', 14, note: 'Recount');

print(service.searchProducts(query: 'iphone'));
print(service.dashboard().totalStockValue);
```

### Rules enforced

- ❌ SKU and product ID must be unique within the shop
- ❌ Quantity must be greater than 0 for stock in and out
- ❌ You cannot sell more than you have on hand
- ❌ An adjusted quantity cannot be negative
- ❌ A supplier must exist before it can be linked to a delivery

Violations throw `StateError` or `ArgumentError` with a clear message.

---

## 🎬 What the demo shows

`main.dart` walks through the app in six steps:

1. Setup of a supplier and three products
2. Stock in, stock out and adjustment
3. Business rules blocking bad operations
4. Search and status filters
5. Today's transactions and totals
6. Dashboard summary and restock prediction

---

## 🛣 Roadmap

- [ ] Persistence (SQLite / Hive)
- [ ] Flutter UI: Home, Product, Transaction and Supplier screens
- [ ] Unit tests (the service takes an injectable clock, so date logic is testable)
- [ ] Export reports to CSV

---

Built with ❤️ in Dart.
