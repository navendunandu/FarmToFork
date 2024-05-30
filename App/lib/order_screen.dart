import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmtofork/order_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _bookingData = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
  try {
    final user = _auth.currentUser;
    final userId = user?.uid;
    if (userId != null) {
      QuerySnapshot userSnapshot =
          await _db.collection('tbl_user').where('uid', isEqualTo: userId).get();
      if (userSnapshot.docs.isNotEmpty) {
        String uDoc = userSnapshot.docs.first.id;

        // Fetch all bookings for the current user
        QuerySnapshot bookingSnapshot = await _db
            .collection('tbl_booking')
            .where('user_id', isEqualTo: uDoc)
            .orderBy('booking_date', descending: true)
            .get();

        // Filter the bookings based on the booking status
        List<Map<String, dynamic>> filteredBookings = [];
        for (var doc in bookingSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['booking_status'] >= 1) {
            data['id']=doc.id;
            filteredBookings.add(data);
          }
        }

        setState(() {
          _bookingData = filteredBookings;
        });
      } else {
        // Handle the case where there is no user document
        print('No user document found');
      }
    } else {
      // Handle the case where the user is not logged in
      print('User is not logged in');
    }
  } catch (e) {
    print('Error fetching booking data: $e');
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      // ... appbar code
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightGreen[200]!, Colors.lightGreen[800]!],
          ),
      ),
      child: _bookingData.isEmpty
          ? Center(
              child: Text('No orders found'),
            )
          : ListView.builder(
              itemCount: _bookingData.length,
              itemBuilder: (context, index) {
                final booking = _bookingData[index];
                // DateTime bookingDate = DateTime.parse();
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderItem(id: booking['id']),)) ;
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Date: ${booking['booking_date']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Booking Amount: Rs.${booking['booking_amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Booking Status: ${_getBookingStatus(booking['booking_status'])}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

  String _getBookingStatus(int status) {
    switch (status) {
      case 1:
        return 'Confirmed';
      case 2:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}
