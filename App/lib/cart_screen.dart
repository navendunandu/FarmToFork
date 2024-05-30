import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtofork/payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> cartData = [];
  double totalPrice = 0.0;

  Future<void> fetchData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      QuerySnapshot userSnapshot =
          await db.collection('tbl_user').where('uid', isEqualTo: userId).get();
      String uDoc = userSnapshot.docs.first.id;
      QuerySnapshot bookingSnapshot = await db
          .collection('tbl_booking')
          .where('user_id', isEqualTo: uDoc)
          .where('booking_status', isEqualTo: 0)
          .limit(1)
          .get();
      String bookingId = bookingSnapshot.docs.first.id;

      QuerySnapshot cartSnapshot = await db
          .collection('tbl_cart')
          .where('booking_id', isEqualTo: bookingId)
          .where('cart_status', isEqualTo: 0)
          .get();
      List<Map<String, dynamic>> vegData = [];

      for (var doc in cartSnapshot.docs) {
        Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>; // Ensure data is not null
        data['id'] = doc.id;
        Map<String, dynamic>? vegInfo = await getVeg(doc['product_id']);
        if (vegInfo != null) {
          data['vegetable_name'] = vegInfo['vegname'];
          data['vegetable_photo'] = vegInfo['vegPhoto'];
          data['vegetable_price'] = double.parse(vegInfo['vegPrice']);
          vegData.add(data);
        }
      }

      setState(() {
        cartData = vegData;
        updateTotalPrice();
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<Map<String, dynamic>?> getVeg(id) async {
    print('Fetching vegetable Data');
    try {
      DocumentSnapshot<Map<String, dynamic>> vegSnapshot =
          await db.collection('tbl_vegetable').doc(id).get();
      String vegname = vegSnapshot['vegetable_name'].toString();
      String vegPhoto = vegSnapshot['vegetable_photo'].toString();
      String vegPrice = vegSnapshot['vegetable_price'].toString();
      return {
        'vegname': vegname,
        'vegPhoto': vegPhoto,
        'vegPrice': vegPrice,
      };
    } catch (e) {
      print('Error getting vegetable data: $e');
      return null;
    }
  }

  void updateTotalPrice() {
    totalPrice = 0.0;
    for (var item in cartData) {
      totalPrice += item['vegetable_price'] * item['cart_qty'];
    }
  }

  void removeFromCart(String id) async {
    try {
      await db.collection('tbl_cart').doc(id).delete();
      fetchData();
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  void updateCartQuantity(String id, int newQuantity) async {
    try {
      await db.collection('tbl_cart').doc(id).update({'cart_qty': newQuantity});
      fetchData();
    } catch (e) {
      print('Error updating cart quantity: $e');
    }
  }

  void checkout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      QuerySnapshot userSnapshot =
          await db.collection('tbl_user').where('uid', isEqualTo: userId).get();
      String uDoc = userSnapshot.docs.first.id;

      QuerySnapshot bookingSnapshot = await db
          .collection('tbl_booking')
          .where('user_id', isEqualTo: uDoc)
          .where('booking_status', isEqualTo: 0)
          .limit(1)
          .get();
      String bookingId = bookingSnapshot.docs.first.id;

      await db.collection('tbl_booking').doc(bookingId).update({
        'booking_status': 1,
        'booking_amount': totalPrice,
      });

      QuerySnapshot cartSnapshot = await db
          .collection('tbl_cart')
          .where('booking_id', isEqualTo: bookingId)
          .where('cart_status', isEqualTo: 0)
          .get();

      for (var doc in cartSnapshot.docs) {
        await db.collection('tbl_cart').doc(doc.id).update({
          'cart_status': 2,
        });
      }

      // Redirect to payment page
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentPage(bid: bookingId,),));
    } catch (e) {
      print('Error during checkout: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 141, 221, 145),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('My Cart'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightGreen[300]!,
              Colors.green[900]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartData.length,
                itemBuilder: (context, index) {
                  final item = cartData[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
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
                                    'Total: \$${(item['vegetable_price'] * item['cart_qty']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    removeFromCart(item['id']);
                                  },
                                ),
                                SizedBox(height: 8.0),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    // Show a dialog to update the quantity
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Update Quantity'),
                                        content: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: TextEditingController(
                                            text: item['cart_qty'].toString(),
                                          ),
                                          onChanged: (value) {
                                            int newQuantity =
                                                int.tryParse(value) ?? 0;
                                            updateCartQuantity(
                                                item['id'], newQuantity);
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
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
                  ElevatedButton(
                    onPressed: () {
                      checkout();
                    },
                    child: Text('Checkout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
