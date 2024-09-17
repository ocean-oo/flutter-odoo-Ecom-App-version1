import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:odoo_rpc/odoo_rpc.dart';

import 'data/models/order.dart';
import 'data/models/product.dart';
import 'package:flutter_badged/flutter_badge.dart';

import 'data/utils/palette.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter odoo app',),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Debouncer {
  final int milliseconds;
  late VoidCallback action;
  late Timer _timer;
  Debouncer({required this.milliseconds}){
    _timer = Timer(Duration(milliseconds: 0), () {}); // Initialize _timer
  }

  run(VoidCallback action) {
    _timer.cancel();
      _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var count = 10;
  bool check = true;
  bool isHoveredOnBasketButton = false; // Track hover state


  List<Product> productsList = [];
  List<Product> data = []; //tmp data to fill search

  // List<Map<String,dynamic>> pannier = [];
  List<Order> pannier = [];
  int orderLength = 0;
  final _debouncer = Debouncer(milliseconds: 300);
  TextEditingController searchButtonController = new TextEditingController();

  late OdooSession prev_session ;

  var url = 'https://2a6d-160-177-123-249.ngrok-free.app';
  late OdooClient authRPC = OdooClient(url); //http://192.168.1.13:8069

  late int currentOderID;

  List<int> productsSelected   = [];
  int currentIndex = -1;



  @override
  void initState() {
    super.initState();

    debugPrint("start initstate");
    authToOdoo();

    // _getOrders();
    // fetchContacts();
  }


  Future<void> authToOdoo()async {
    try {
      var session = await authRPC.authenticate('company_name', 'yourEmail@exemple.com', 'your_odoo_password');
      sessionChanged(session);

      if (session != null) { //!
        var user = {};
        user["id"] = session.userId;
        user["name"] = session.userName;

        final box = GetStorage();
        box.write('userId', '${user["id"]}');

        print("Hey ${user}");
        var userId = box.read('userId');

      } else {
        print("Login failed");
      }

      final res = await authRPC.callRPC('/web/session/modules', 'call', {});
      print('Installed modules: \n' + res.length.toString());

    } on OdooException catch (e) {
      debugPrint("OdooException Error 84");
      print(e.message); // Print the exception message
      print(e);
      authRPC.close();
      exit(-1);
    }
    // authRPC.close();

  }


  Future<dynamic> fetchContacts() async {
    var result = await
    authRPC.callKw({
      'model': 'res.partner',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'context': {'bin_size': true},
        'domain': [],
        'fields': ['id', 'name', 'email', '__last_update', 'image_128'],
        'limit': 80,
      },
    });
    return result;
  }

  Future<dynamic> getOrders() async {

    List<String> ordersFields = [ 'id', 'name', 'date_order', 'config_id','partner_id','lines', 'amount_total'];

    var result =
    await authRPC.callRPC("/web/dataset/search_read",'',{
      "model":"pos.order",
      "fields": ordersFields,
      'domain': [],
      'limit': 80,
    });
    return result;
  }



  Future<dynamic> createOrder(Map<String, Object> orderData) async {

    var now = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    double amountTotal = 0.0;

    pannier.forEach((element) {
      amountTotal = amountTotal + (element.totalCost ?? 0.0); });
    Map<String, Object> orderData = {
      "session_id": 1,
      "company_id": 1,
      "access_token": false,
      "name": "Shop/000${orderLength+1}", //count orders +1
      "pos_reference": "Order 00001-048-00${orderLength+1}",
      "date_order": formattedDate, //datetime now
      "user_id": 2, //get userID
      "config_id": 1,
      "amount_return": 0.0,
      "amount_paid": amountTotal, //before exchange
      "amount_total": amountTotal,
      "amount_tax": 0.0,//amountTotal * 0.2, // 20 % TVA
      "margin": 20.0,
      "partner_id": false,
      "pricelist_id": 1,
      "currency_id": 109,
      "note": "add some note here",
      "is_total_cost_computed": true,
      "lines": [],
    };

    var result = await authRPC.callRPC(
      "/web/dataset/call_kw",
      "",
      {
        "model": "pos.order",
        "method": "create",
        "args": [orderData],
        "kwargs": {},
      },
    );

    if (result != null) {
      // Order creation was successful, and the result contains the created order data.
      currentOderID = result;
      orderLength++;
      return result;
    } else {
      // There was an error in creating the order.
      print("Error in creating order: ${result['error']}");
      return null;
    }
  }


  Future<void> createOrderLines(int orderID) async {

    List<Map<String, dynamic>> orderLinesTest = [
      {
        "order_id": orderID,
        "name": "test sale order 28+",
        "full_product_name": "Office Chair II+1",
        "product_id": 5,
        "total_cost": 45.0,
        "price_subtotal": 91.0,
        "price_subtotal_incl": 81.0,
        "price_unit": 60.0,
        "qty": 2.0,
        "product_uom_id": [3, "Units"],
        "currency_id": [109, "MAD"],
        "price_extra": 0.0,
        "margin": 15.0,
        "margin_percent": 0.21430000000000002
      },
      {
        "order_id": orderID,
        "name": "test sale order 28+2",
        "full_product_name": "Office Chair II+2",
        "product_id": 5,
        "total_cost": 45.0,
        "price_subtotal": 91.0,
        "price_subtotal_incl": 81.0,
        "price_unit": 60.0,
        "qty": 2.0,
        "product_uom_id": [3, "Units"],
        "currency_id": [109, "MAD"],
        "price_extra": 0.0,
        "margin": 15.0,
        "margin_percent": 0.21430000000000002
      }
    ];

    pannier.forEach((element) {
      element.orderId = orderID;
    });

    List<Map<String, dynamic>> orderLines=[];
    pannier.forEach((element) {
      orderLines.add(element.toMap());
    });

    debugPrint('---\n');
    debugPrint('${orderLines}');


    debugPrint('---\n');

    var result = await authRPC.callRPC("/web/dataset/call_kw", '', {
      "model": "pos.order.line",
      "method": "create",
      "args": [orderLines],
      "kwargs": {}
    });


    if (result != null) {
      print("Order lines created successfully");
      debugPrint('lines: ${result}');

    } else {
      print("Error creating order lines");
    }

  }


  Future<void> addProductToBasket(Product productData) async{

    Map<String, dynamic> newLineOrderMap =
    {
      "order_id": null,
      "full_product_name": productData.fullName,
      "product_id": productData.productId,
      "total_cost": productData.totalCost,//productData['list_price'] * qty
      "price_subtotal": productData.totalCost, //price before tax productData[taxes_id] =[]
      "price_subtotal_incl": productData.totalCost, //price_subtotal + tax
      "price_unit": productData.totalCost, //list_price
      "price_extra": 0.0,

      "qty": 1.0,
      "currency_id": [109, "MAD"],
      // "product_uom_id": [3, "Units"],
      // "margin": 15.0,
      // "margin_percent": 0.21430000000000002
    };
    Order newOrederLine= Order.fromMap(newLineOrderMap);

    debugPrint('--- pannier.contains(newOrederLine) : ${pannier.contains(newOrederLine)} -- ');



        pannier.forEach((element) =>
        element.productId == newOrederLine.productId ?
          {
            element.qty = (element.qty!+1.0)!,
          }
           :{
            pannier.add(newOrederLine)
           }
        );



    debugPrint('--- pannier -- ');
    debugPrint('${pannier}');

  }


  Future<dynamic> fetchOrders_old() async {
    print("-- test get orders--");
    var result = await authRPC.callKw({
      'model': 'sale.order', // Specify the Odoo model for orders
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'context': {'bin_size': true},
        'domain': [], // You can add a domain filter if needed
        'fields': [
          'id',
          'name',  // Order name
          'date_order',  // Order date
          'partner_id',  // Customer (partner) associated with the order
          'amount_total',  // Total amount of the order
          // Add other fields you need here
        ],
        'limit': 80, // Limit the number of records returned
      },
    });
    return result;
  }



  void confirmOrder() {
    // Implement order confirmation logic here
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Confirmed'),
          content: Text('Your order has been placed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                pannier.isNotEmpty?
                setState(() async {
                  currentIndex = -1;
                  productsSelected = [];
                  pannier.clear();
                  pannier = [];
                })
                    :{};
              },
              child: Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                pannier.isNotEmpty?
                setState(() async {
                  //change state of order

                  debugPrint("confirm order");
                  var orderID = await createOrder({});
                  debugPrint("--- end long press  : $orderID ----");

                  createOrderLines(orderID);
                  pannier.clear();
                  pannier = [];

                })
                    :{};

                // Navigator.of(context).pop();

              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  Future<List>? _getProducts() async {
    var productsFields = ["id","display_name","name","image_128","qty_available","list_price","standard_price","currency_id","uom_id","display_name"];
    var result =
        await authRPC.callRPC("/web/dataset/search_read",'',{
          "model":"product.template",
          "fields":productsFields,
        });

    print('-- tmpData 11 ---');

    if (result.hashCode > 0) { //if negative , error
      setState(() {
        check = false;
        List tmpData = result['records'];

        print('-- tmpData ---');
        print(tmpData);
        print('-- tmpData 2---');

        tmpData.forEach((element) {
          data.add(Product.fromMap(element));
        });

        data.forEach((element) {
          productsList.add(element);
        });

        orderLength = productsList.length;
        print("Products length : ${productsList.length}");
      });
    }
    else {
      print("Error in getting products data");}
    return data; //+
  }

  void sessionChanged(OdooSession sessionId) async {
    print('-------\n'
        'We got new session: ${sessionId}'
        '\nWe got new session ID: ${sessionId.id}'
        '\n-------');
    prev_session = sessionId;
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar:

        AppBar(
          centerTitle: true,
          title: TextField(
            style: TextStyle(
              fontSize: 15.0,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(10.0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: BorderSide.none),
              hintText: "Search..",
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black,
              ),
              suffixIcon: Icon(
                Icons.filter_list,
                color: Colors.black,
              ),
              hintStyle: TextStyle(
                fontSize: 15.0,
                color: Colors.black,
              ),
            ),
            maxLines: 1,
            controller: searchButtonController,
            onChanged: (string) {
              debugPrint("String to search -- $string");

              _debouncer.run(() {
                setState(() {
                  productsList = data
                      .where((u) => (u.fullName
                              !.toLowerCase()
                              .contains(string.toLowerCase()) ||
                          u.totalCost
                              .toString()
                              .toLowerCase()
                              .contains(string.toLowerCase())))
                      .toList();
                });
              });
            },
          ),
          leading:
          ElevatedButton(
            onPressed:() async {
              _getProducts();
              print("-------- orders : --- "); //!
              var orders = await getOrders();
              print(orders); //!
              print("------------\n\n"); //!

            },
            child:
            Icon(
              Icons.shopping_cart,
              color: Colors.black,
            ),
          ),

          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Colors.blue, Colors.blue])),
          ),
        ),

        body: check
            ? Center(
                child: CircularProgressIndicator(),)
            : productsList.length == 0
                ? Center(
                    child: Text("No Data Found"),
                  )
                : Container(
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: productsList.length,
                        itemBuilder: (context, int index) {
                          return Container(
                            margin: EdgeInsets.all(4),
                            child: Card(
                              elevation: 2,
                              child: ListTile(

                                selected: productsSelected.contains(index) ? true: false,
                                selectedTileColor: productsSelected.contains(index) ? Palette.kSecondaryColor :Colors.white,
                                onTap: (){

                                  currentIndex = index;
                                  productsSelected.contains(currentIndex) ?
                                  {
                                    productsSelected.remove(currentIndex),
                                    //rm
                                    //addProductToBasket(productsList[index])
                                  pannier.removeWhere((element) => element.productId == productsList[index].productId),
                                }
                                      :
                                  {
                                    productsSelected.add(currentIndex),
                                    addProductToBasket(productsList[index])
                                  };
                                  setState(() {
                                  });
                                },
                                onLongPress: (){
                                  productsSelected.add(currentIndex);
                                  addProductToBasket(productsList[index]);
                                  setState(() {

                                  });
                                },
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child:
                                      productsList[index].image != false ?
                                      Image.memory(
                                          base64Decode(
                                            productsList[index].image!
                                          ),
                                          fit: BoxFit.cover,
                                          width: screenWidth / 1,
                                          height: screenHight / 3
                                      )
                                          :
                                      SizedBox.shrink(),//

                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      productsList[index].fullName ?? '',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Text(productsList[index].currencyId?[1]),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          productsList[index].totalCost
                                              .toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  ),

      floatingActionButton:
      Container(
        width: isHoveredOnBasketButton ? 65 :200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: isHoveredOnBasketButton ? Palette.kPrimaryColor : Palette.kSecondaryColor,
        ),
        child:
        ElevatedButton(
          onPressed: () {
            // Add to Panier action
            setState(() {
              isHoveredOnBasketButton = !isHoveredOnBasketButton;
            });

            confirmOrder();
            },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            // backgroundColor: isHoveredOnBasketButton ? Palette.kPrimaryColor : Palette.kSecondaryColor,
            elevation: 0, // Remove button shadow
          ),
          child:
          Row(
            mainAxisAlignment : MainAxisAlignment.end,
            children: [

              const Icon(
                Icons.shopping_cart,
                color: Palette.aliceColor,
              ),
              const SizedBox(width: 8),

              !isHoveredOnBasketButton ?
              const Text(
                'Ajouter au panier',
                style: TextStyle(fontSize: 16, color: Palette.aliceColor),
              )
                  :
              FlutterBadge(
                icon: SizedBox(
                  height: 40,),
                badgeColor: Palette.kSecondaryColor,
                badgeTextColor: Colors.black,
                // position: BadgePosition.bottomLeft(),
                itemCount: pannier.length,
              ),
            ],
          ),
        ),
      ),

    );
  }
}
