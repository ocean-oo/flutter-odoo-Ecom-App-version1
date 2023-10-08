import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:odoo_api/odoo_api.dart';
// import 'package:odoo_api/odoo_api_connector.dart';
// import 'package:odoo_api/odoo_user_response.dart';
// import 'package:task/image.dart';
import 'dart:io';
import 'package:odoo_rpc/odoo_rpc.dart';


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
  List productsList = [];
  List data = []; //tmp data to fill search
  var imageView;
  final _debouncer = Debouncer(milliseconds: 300);
  TextEditingController searchButtonController = new TextEditingController();

  late OdooSession prev_session ;

  var url = 'https://4cfb-160-177-217-141.ngrok-free.app';
  late OdooClient authRPC = OdooClient(url); //http://192.168.1.13:8069

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
      var session = await authRPC.authenticate('sodev', 'tarik.sodev@gmail.com', 'odoo@@16');
      sessionChanged(session);

      if (session != null) { //!
        var user = {};
        user["id"] = session.userId;
        user["name"] = session.userName;

        print("Hey ${user}");
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


  Future<Map<String, dynamic>?> createOrder(Map<String, Object> orderData) async {
    Map<String, Object> orderData = {
      "session_id": 1,
      "company_id": 1,
      "access_token": false,
      "name": "Shop/000 test 3",
      "pos_reference": "Order 00001-048-0003",
      "date_order": "2023-10-08 12:48:01",
      "user_id": 2, //
      "config_id": 1,
      "amount_return": 0.0,
      "amount_paid": 400.0,
      "amount_total": 200.0,
      "amount_tax": 80.0,
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

    if (result['result'] != null) {
      // Order creation was successful, and the result contains the created order data.
      return result['result'];
    } else {
      // There was an error in creating the order.
      print("Error in creating order: ${result['error']}");
      return null;
    }
  }


  Future<void> createOrderLines(List<Map<String, Object>> orderLines) async {
    List<Map<String, Object>> orderLines = [
      {
        "order_id": 38,
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
        "order_id": 38,
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

    var result = await authRPC.callRPC("/web/dataset/call_kw", '', {
      "model": "pos.order.line",
      "method": "create",
      "args": [orderLines],
      "kwargs": {}
    });

    if (result != null && result.containsKey("result")) {
      print("Order lines created successfully");
    } else {
      print("Error creating order lines");
    }
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





  Future<List>? _getOrders() async {
    var productsFields = ["id","display_name","name","image_128","qty_available","list_price","standard_price","currency_id","uom_id","display_name"];
    var result =
        await authRPC.callRPC("/web/dataset/search_read",'',{
          "model":"product.template",
          "fields":productsFields,
        });
    if (result.hashCode > 0) { //if negative , error
      setState(() {
        check = false;
        data = result['records'];
        productsList = data;
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
                      .where((u) => (u['name']
                              .toString()
                              .toLowerCase()
                              .contains(string.toLowerCase()) ||
                          u['list_price']
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
              _getOrders();
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
                                onLongPress:(){

                                  createOrder({});
                                },
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child:
                                      productsList[index]['image_128'] != false ?
                                      Image.memory(
                                          base64Decode(
                                            productsList[index]['image_128']
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
                                      productsList[index]['name'].toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Text(productsList[index]['currency_id'][1]),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          productsList[index]['list_price']
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
                  ));
  }
}
