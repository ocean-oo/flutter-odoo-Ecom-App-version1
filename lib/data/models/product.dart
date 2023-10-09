class Product {
  String? fullName;
  String? image;
  int? productId;
  int? orderId;

  double? totalCost;
  double? priceSubtotal;
  double? priceSubtotalIncl;
  double? priceUnit;
  double? priceExtra;
  double? qty_wanted;
  List? currencyId;

  Product({
    this.fullName,
    this.image,
    this.productId,
    this.orderId,

    this.totalCost,
    this.priceSubtotal,
    this.priceSubtotalIncl,
    this.priceUnit,
    this.priceExtra,
    this.qty_wanted,
    this.currencyId,
  });

  // Named constructor to create a Product from a map
  Product.fromMap(Map<String, dynamic> map)
      :
        fullName = map['name'],
        productId = map['id'],
        orderId = map['order_id'],
        image = map['image_128'] !=  false ? map['image_128'] : null,
        totalCost = map['list_price'],
        qty_wanted = map['qty'],
        currencyId = map['currency_id'];

  // Method to convert a Product object to a map
  Map<String, dynamic> toMap() {
    return {
      'order_id': null,
      'full_product_name': fullName,
      'product_id': productId,
      'total_cost': totalCost,
      'price_subtotal': totalCost, //just now
      'price_subtotal_incl': totalCost,
      'price_unit': totalCost,
      'price_extra': priceExtra,
      'qty': qty_wanted,
      'currency_id': currencyId?[1],
    };
  }

  @override
  String toString() {
    return 'Product{fullName: $fullName, productId: $productId, orderId: $orderId, totalCost: $totalCost, priceSubtotal: $priceSubtotal, priceSubtotalIncl: $priceSubtotalIncl, priceUnit: $priceUnit, priceExtra: $priceExtra, qty: $qty_wanted, currencyId: $currencyId,image: $image}';
  }
}



// Inside your _ProductListScreenState class
// void addToCart(Map<String, dynamic> productData) {
//   final product = Product(
//     orderId: productData['order_id'] ?? "",
//     fullName: productData['full_product_name'],
//     productId: productData['product_id'],
//     totalCost: productData['total_cost'],
//     priceSubtotal: productData['price_subtotal'],
//     priceSubtotalIncl: productData['price_subtotal_incl'],
//     priceUnit: productData['price_unit'],
//     priceExtra: productData['price_extra'],
//     qty: productData['qty'],
//     currencyId: productData['currency_id'],
//   );
//
// }
