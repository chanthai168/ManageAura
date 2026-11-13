class DashboardSummary {
  final double totalStockValue;
  final int todayTransactions;
  final int totalProducts;
  final int totalCategories;
  final int lowStockCount;
  final int outOfStockCount;

  DashboardSummary({
    required this.totalStockValue,
    required this.todayTransactions,
    required this.totalProducts,
    required this.totalCategories,
    required this.lowStockCount,
    required this.outOfStockCount,
  });
}