/// Kind of stock movement (matches the filter chips on the Transaction screen:
/// All / Stock in / Stock out / Adjust).
enum TransactionType { stockIn, stockOut, adjust }

/// Stock badge shown on the Product screen (In stock / Low stock / Out of stock).
enum StockStatus { inStock, lowStock, outOfStock }

/// Period chips on the Transaction screen (Today / This week / This month).
enum TransactionPeriod { today, thisWeek, thisMonth }
