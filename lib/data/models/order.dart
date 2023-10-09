class Order {
  int? orderId;
  String? fullProductName;
  int? productId;
  double? totalCost;
  double? priceSubtotal;
  double? priceSubtotalIncl;
  double? priceUnit;
  double? priceExtra;
  double? qty;
  List<dynamic>? currencyId;

  Order({
    this.orderId,
    this.fullProductName,
    this.productId,
    this.totalCost,
    this.priceSubtotal,
    this.priceSubtotalIncl,
    this.priceUnit,
    this.priceExtra,
    this.qty,
    this.currencyId,
  });

  // Named constructor to create an Order from a map
  Order.fromMap(Map<String, dynamic> map)
      : orderId = map['order_id'],
        fullProductName = map['full_product_name'],
        productId = map['product_id'],
        totalCost = map['total_cost'],
        priceSubtotal = map['price_subtotal'],
        priceSubtotalIncl = map['price_subtotal_incl'],
        priceUnit = map['price_unit'],
        priceExtra = map['price_extra'],
        qty = map['qty'],
        currencyId = map['currency_id'];

  // Method to convert an Order object to a map
  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'full_product_name': fullProductName,
      'product_id': productId,
      'total_cost': totalCost,
      'price_subtotal': priceSubtotal,
      'price_subtotal_incl': priceSubtotalIncl,
      'price_unit': priceUnit,
      'price_extra': priceExtra,
      'qty': qty,
      'currency_id': currencyId,
    };
  }

  @override
  String toString() {
    return 'Order{orderId: $orderId, fullProductName: $fullProductName, productId: $productId, totalCost: $totalCost, priceSubtotal: $priceSubtotal, priceSubtotalIncl: $priceSubtotalIncl, priceUnit: $priceUnit, priceExtra: $priceExtra, qty: $qty, currencyId: $currencyId}';
  }
}