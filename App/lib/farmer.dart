import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class FarmerPage extends StatefulWidget {
  final String id;
  const FarmerPage({super.key, required this.id});

  @override
  State<FarmerPage> createState() => _FarmerPageState();
}

class _FarmerPageState extends State<FarmerPage> {
  List<Map<String, dynamic>> farmerData = [];
  List<Map<String, dynamic>> vegetableData = [];

  String? selectedCategory;
  String? name;
  String? dist;
  String? place;
  String? imageUrl;

  TextEditingController keywordController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchAndSetFarmerData();
    fetchVegetables();
  }

  Future<void> fetchAndSetFarmerData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await db.collection('tbl_farmer').doc(widget.id).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> farmer = docSnapshot.data()!;
        farmer['id'] = docSnapshot.id; // Include the document ID

        // Call fetchLocation function with the place_id
        Map<String, dynamic>? locationData =
            await fetchLocation(farmer['place_id']);

        setState(() {
          name = farmer['farmer_name'];
          dist = locationData?['district'];
          place = locationData?['places'];
          imageUrl = farmer['farmer_photo'];
        });
      } else {
        print('Document with ID ${widget.id} does not exist');
        // Handle the case where the document doesn't exist
      }
    } catch (e) {
      print("Error fetching and setting farmer data: $e");
      // Handle the error as needed
    }
  }

  Future<Map<String, dynamic>?> fetchLocation(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> placeSnapshot =
          await db.collection('tbl_place').doc(id).get();

      String placeName = placeSnapshot['place_name'].toString();
      String distid = placeSnapshot['district_id'].toString();

      // Fetch district information
      DocumentSnapshot<Map<String, dynamic>> districtSnapshot =
          await db.collection('tbl_district').doc(distid).get();

      // Extract district name
      String districtName = districtSnapshot['district_name'].toString();

      // Return the district name and place names as a map
      return {
        'district': districtName,
        'places': placeName,
      };
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> fetchVegetables() async {
    try {
      QuerySnapshot vegetableSnapshot = await FirebaseFirestore.instance
          .collection('tbl_vegetable')
          .where('farmer_id', isEqualTo: widget.id)
          .get();
      List<Map<String, dynamic>> vegData = [];
      vegetableSnapshot.docs.forEach((doc) async {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        data?['id'] = doc.id;
        // Fetch category name based on category_id
        String categoryName = await getCategoryName(data?['category_id']);
        data?['category_name'] = categoryName;
        vegData.add(data!);
      });
      setState(() {
        vegetableData = vegData;
      });
    } catch (e) {
      print('Vegetables error: $e');
    }
  }

  Future<void> search(keyword) async {
    try {
      QuerySnapshot vegetableSnapshot = await FirebaseFirestore.instance
          .collection('tbl_vegetable')
          .where('farmer_id', isEqualTo: widget.id)
          .where('vegetable_name', arrayContains: keyword)
          .get();
      List<Map<String, dynamic>> vegData = [];
      if (vegetableSnapshot.docs.isNotEmpty) {
        vegetableSnapshot.docs.forEach((doc) async {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        data?['id'] = doc.id;
        // Fetch category name based on category_id
        String categoryName = await getCategoryName(data?['category_id']);
        data?['category_name'] = categoryName;
        vegData.add(data!);
      });
      setState(() {
        vegetableData = vegData;
      });
      }
      else{
        print('No data found');
      }
      
    } catch (e) {
      print('Vegetables error: $e');
    }
  }

  Future<String> getCategoryName(String categoryId) async {
    try {
      DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('tbl_category')
          .doc(categoryId)
          .get();

      // Check if the document exists and contains the 'name' field
      if (categorySnapshot.exists &&
          categorySnapshot.get('category_name') != null) {
        return categorySnapshot.get('category_name') as String;
      } else {
        // Return a default value or handle the null case accordingly
        return 'Category Name Not Found';
      }
    } catch (e) {
      print("Error getting category name: $e");
      // Return a default value or handle the error case accordingly
      return 'Error Getting Category Name';
    }
  }

  Future<int> getStock(String id, dynamic stock) async {
  try {
    QuerySnapshot<Map<String, dynamic>> cartSnapshot = await FirebaseFirestore
        .instance
        .collection('tbl_cart')
        .where('product_id', isEqualTo: id)
        .where('cart_status', isEqualTo: 1)
        .get();

    int totalStock = 0;
    for (DocumentSnapshot<Map<String, dynamic>> doc in cartSnapshot.docs) {
      int cartQty = doc['cart_qty'] ?? 0;
      totalStock += cartQty;
    }

    int remainingStock = 0;
    if (stock is int) {
      remainingStock = stock - totalStock;
    } else if (stock is String) {
      remainingStock = int.parse(stock) - totalStock;
    } else {
      print('Unknown stock data type: $stock');
    }

    return remainingStock;
  } catch (e) {
    print('Error Getting Stock: $e');
    return 0;
  }
}

  Future<void> addcart(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot userSnapshot = await firestore
          .collection('tbl_user')
          .where('uid', isEqualTo: userId)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String uDoc = userSnapshot.docs.first.id;
        try {
          QuerySnapshot bookingSnapshot = await firestore
              .collection('tbl_booking')
              .where('user_id', isEqualTo: uDoc)
              .where('booking_status', isEqualTo: 0)
              .limit(1)
              .get();

          if (bookingSnapshot.docs.isNotEmpty) {
            String bookingId = bookingSnapshot.docs.first.id;
            try {
              QuerySnapshot querySnapshot = await firestore
                  .collection('tbl_cart')
                  .where('product_id', isEqualTo: id)
                  .where('booking_id', isEqualTo: bookingId)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                Fluttertoast.showToast(
                  msg: 'Already in cart',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.blue,
                  textColor: Colors.white,
                );
              } else {
                await addToCart(id, bookingId);
              }
            } catch (e) {
              print('Error querying cart: $e');
              Fluttertoast.showToast(
                msg: 'Error querying cart',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          } else {
            try {
              String currentDate =
                  DateFormat('yyyy-MM-dd').format(DateTime.now());
              Map<String, dynamic> bookingData = {
                'booking_date': currentDate,
                'booking_status': 0,
                'user_id': uDoc,
              };

              DocumentReference documentReference =
                  await firestore.collection('tbl_booking').add(bookingData);
              String documentId = documentReference.id;
              await addToCart(id, documentId);
            } catch (e) {
              print('Error inserting to booking: $e');
              Fluttertoast.showToast(
                msg: 'Error inserting to booking',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          }
        } catch (e) {
          print('Error querying booking: $e');
          Fluttertoast.showToast(
            msg: 'Error querying booking',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error AddCart: $e');
      Fluttertoast.showToast(
        msg: 'Error AddCart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> addToCart(String id, String bid) async {
    try {
      Map<String, dynamic> cartItem = {
        'booking_id': bid,
        'product_id': id,
        'cart_status': 0,
        'cart_qty': 1,
      };
      await FirebaseFirestore.instance.collection('tbl_cart').add(cartItem);
      Fluttertoast.showToast(
        msg: 'Added to Cart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error adding cart: $e');
      Fluttertoast.showToast(
        msg: 'Error adding cart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer Profile
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farmer's photo
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const SizedBox(
                        width: 80,
                        height: 80,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? 'Farmer Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'District: ${dist ?? 'District Name'}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Place: ${place ?? 'Place Name'}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Keyword to Search'
              ),
              controller: keywordController,
              onChanged: (value) {
                search(value);
              },
            ),
          ),

          // Vegetables
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: vegetableData.length,
                itemBuilder: (context, index) {
                  final vegetable = vegetableData[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vegetable photo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: vegetable['vegetable_photo'] != null
                                ? Image.network(
                                    vegetable['vegetable_photo']!,
                                    width: 100,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                          padding: EdgeInsets.all(18),
                                          width: 100,
                                          height: 100,
                                          child: CircularProgressIndicator());
                                    },
                                  )
                                : Container(
                                    padding: EdgeInsets.all(18),
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vegetable['vegetable_name'] ??
                                      'Vegetable Name',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Category: ${vegetable['category_name'] ?? 'Category Name'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Price: ${vegetable['vegetable_price'] is String ? double.parse(vegetable['vegetable_price']) : vegetable['vegetable_price']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<int>(
                                  future: getStock(vegetable['id'],
                                      vegetable['vegetable_stock']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return const Text('Error getting stock');
                                    } else {
                                      int stock = snapshot.data ?? 0;
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Text('Stock: '),
                                              Text(stock.toString()),
                                              const SizedBox(width: 16),
                                            ],
                                          ),
                                          if (stock > 0)
                                            ElevatedButton(
                                              onPressed: () {
                                                // Add vegetable to cart logic
                                                addcart(vegetable['id']);
                                              },
                                              child: const Text('Add to Cart'),
                                            )
                                          else
                                            const Text('Out of Stock'),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
