import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:odoo_api/odoo_api.dart';
// import 'package:odoo_api/odoo_api_connector.dart';
// import 'package:odoo_api/odoo_user_response.dart';
import 'package:task/image.dart';
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
    if (null != _timer) {
      _timer.cancel();
    }
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

  late OdooClient authRPC = OdooClient("https://6e53-160-177-120-51.ngrok-free.app"); //http://192.168.1.13:8069

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


  Future<dynamic> fetchContacts() {
    var result =
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
    debugPrint("result get contact ");
    debugPrint(result.toString());
    return result;
  }


  Future<List>? _getOrders() async {
    var productsFields = ["id","display_name","name","image_128","qty_available","list_price","standard_price","currency_id","uom_id","display_name"];
    print("----test get product ---");

    var result =
        await authRPC.callRPC("/web/dataset/search_read",'',{
          "model":"product.template",
          "fields":productsFields,
        });
    print("result :");
    log(result.toString());
    debugPrint("---140");



    if (result.hashCode > 0) { //if negative , error
      print("Successful");
      setState(() {
        check = false;

        data = result['records'];
        productsList = data;
        print("CCC---150");
        // print(listdata);
        print(productsList.length);
      });
    }
    else {
      print("Error in getting products data");}

    return data; //+
  }

  void sessionChanged(OdooSession sessionId) async {
    print('-------\n'
        'We got new session ID: ${sessionId.id}'
        '\n-------');
    prev_session = sessionId;
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHight = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
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
            onPressed:() {
              _getOrders();
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
                child: CircularProgressIndicator(),
              )
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
