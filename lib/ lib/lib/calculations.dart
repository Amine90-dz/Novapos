import 'models.dart';

class SaleCalculations {
  static double subtotal(List<SaleItem> items) {
    return items.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  static double discountAmount(
    List<SaleItem> items,
    Discount discount,
  ) {
    final total = subtotal(items);
    return discount.calculate(total);
  }

  static double finalTotal(
    List<SaleItem> items,
    Discount discount,
  ) {
    final total = subtotal(items);
    final discountValue = discount.calculate(total);

    return total - discountValue;
  }

  static double remaining(
    List<SaleItem> items,
    Discount discount,
    double paid,
  ) {
    final total = finalTotal(items, discount);
    final value = total - paid;

    return value < 0 ? 0 : value;
  }
}
