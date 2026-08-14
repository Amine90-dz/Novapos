class Product {
  final String id;
  String name;
  double price;
  int quantity;
  String size;
  String color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'].toString(),
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      size: map['size'].toString(),
      color: map['color'].toString(),
    );
  }
}

class Customer {
  final String id;
  String name;
  String phone;
  double debt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.debt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'debt': debt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'].toString(),
      name: map['name'].toString(),
      phone: map['phone'].toString(),
      debt: (map['debt'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Supplier {
  final String id;
  String name;
  String phone;
  double debt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.debt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'debt': debt,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'].toString(),
      name: map['name'].toString(),
      phone: map['phone'].toString(),
      debt: (map['debt'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum DiscountType {
  amount,
  percentage,
}

class Discount {
  final DiscountType type;
  final double value;

  const Discount({
    required this.type,
    required this.value,
  });

  double calculate(double total) {
    if (type == DiscountType.percentage) {
      return total * value / 100;
    }

    return value > total ? total : value;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'value': value,
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      type: map['type'] == 'percentage'
          ? DiscountType.percentage
          : DiscountType.amount,
      value: (map['value'] as num).toDouble(),
    );
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String size;
  final String color;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.size,
    required this.color,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'size': size,
      'color': color,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'].toString(),
      productName: map['productName'].toString(),
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      size: map['size'].toString(),
      color: map['color'].toString(),
    );
  }
}

class Sale {
  final String id;
  final String date;
  final String customerId;
  final List<SaleItem> items;
  final Discount discount;
  final double paid;

  Sale({
    required this.id,
    required this.date,
    required this.customerId,
    required this.items,
    required this.discount,
    required this.paid,
  });

  double get subtotal {
    return items.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get discountAmount {
    return discount.calculate(subtotal);
  }

  double get total {
    return subtotal - discountAmount;
  }

  double get remaining {
    final value = total - paid;
    return value < 0 ? 0 : value;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'customerId': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'discount': discount.toMap(),
      'paid': paid,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'].toString(),
      date: map['date'].toString(),
      customerId: map['customerId'].toString(),
      items: (map['items'] as List)
          .map(
            (item) => SaleItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      discount: Discount.fromMap(
        Map<String, dynamic>.from(map['discount']),
      ),
      paid: (map['paid'] as num).toDouble(),
    );
  }
}
