import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderItem extends StatefulWidget {
  final String id;
  const OrderItem({super.key, required this.id});

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  double totalPrice = 0.0;
  List<Map<String, dynamic>> itemData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    print(widget.id);
  try {
    QuerySnapshot cartSnapshot = await db
        .collection('tbl_cart')
        .where('booking_id', isEqualTo: widget.id)
        .where('cart_status', isEqualTo: 1)
        .get();

    List<Map<String, dynamic>> vegData = [];
    for (var doc in cartSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      Map<String, dynamic>? vegInfo = await getVeg(data['product_id']);
      if (vegInfo != null) {
        data['vegetable_name'] = vegInfo['vegname'];
        data['vegetable_photo'] = vegInfo['vegPhoto'];
        data['vegetable_price'] = double.parse(vegInfo['vegPrice']);
        vegData.add(data);
      }
    }

    setState(() {
      itemData = vegData;
      updateTotalPrice();
    });
  } catch (e) {
    print('Error fetching cart data: $e');
    // Display an error message or handle the exception in another way
    showErrorDialog('Error fetching cart data');
  }
}

Future<Map<String, dynamic>?> getVeg(id) async {
  try {
    DocumentSnapshot<Map<String, dynamic>> vegSnapshot =
        await db.collection('tbl_vegetable').doc(id).get();

    if (vegSnapshot.exists) {
      Map<String, dynamic>? vegData = vegSnapshot.data();
      if (vegData != null) {
        return {
          'vegname': vegData['vegetable_name'].toString(),
          'vegPhoto': vegData['vegetable_photo'].toString(),
          'vegPrice': vegData['vegetable_price'].toString(),
        };
      }
    } else {
      print('Vegetable document not found: $id');
    }
  } catch (e) {
    print('Error getting vegetable data: $e');
    // Display an error message or handle the exception in another way
    showErrorDialog('Error getting vegetable data');
  }
  return null;
}

void updateTotalPrice() {
  try {
    totalPrice = 0.0;
    for (var item in itemData) {
      totalPrice += item['vegetable_price'] * item['cart_qty'];
    }
  } catch (e) {
    print('Error updating total price: $e');
    // Display an error message or handle the exception in another way
    showErrorDialog('Error updating total price');
  }
}

void showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 240, 233, 226),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Order Details'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightGreen[200]!, Colors.lightGreen[800]!],
          ),
        ),
        child: itemData.isEmpty
            ? Center(
                child: Text('No items found'),
              )
            : ListView.builder(
                itemCount: itemData.length,
                itemBuilder: (context, index) {
                  final item = itemData[index];
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Image.network(
                              item['vegetable_photo'],
                              width: 80,
                              height: 80,
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['vegetable_name'],
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Quantity: ${item['cart_qty']}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Price: \$${item['vegetable_price'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Total: \$${(item['vegetable_price'] * item['cart_qty']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: \$${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}