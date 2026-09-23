class AccountTypes {
  static const String asset = 'Asset';
  static const String liability = 'Liability';
  static const String equity = 'Equity';
  static const String revenue = 'Revenue';
  static const String expense = 'Expense';

  static const List<String> all = [
    asset,
    liability,
    equity,
    revenue,
    expense,
  ];

  static bool isNormalDebit(String type) {
    return type == asset || type == expense;
  }
}
