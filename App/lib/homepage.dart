import 'package:farmtofork/farmer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_screen.dart';
import 'order_screen.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String name = 'Loading...';
  bool _isMounted = false;
  List<Map<String, dynamic>> farmerList = [];
  List<Map<String, dynamic>> district = [];
  List<Map<String, dynamic>> place = [];
  FirebaseFirestore db = FirebaseFirestore.instance;
  String? selectdistrict;
  String? selectplace;
  late ProgressDialog _progressDialog;

  @override
  void initState() {
    super.initState();
    _progressDialog = ProgressDialog(context);
    _isMounted = true;
    loadData();
    fetchFarmers();
    fetchDistrict();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<Map<String, String>?> fetchPlace(id) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('tbl_place')
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        String placeName = docSnapshot['place_name'];
        String districtId = docSnapshot['district_id'];

        return {'place': placeName, 'district_id': districtId};
      } else {
        print('Document with placeId $id does not exist');
        return null;
      }
    } catch (e) {
      print("Error fetching place: $e");
      return null;
    }
  }

  Future<void> fetchFarmers() async {
    try {
      List<Map<String, dynamic>> farmers = [];

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('tbl_farmer').get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        String name = doc['farmer_name'];
        String photo = doc['farmer_photo'];

        Map<String, String>? placeData = await fetchPlace(doc['place_id']);

        if (placeData != null) {
          farmers.add({
            'id': doc.id,
            'name': name,
            'photo': photo,
            'place': placeData,
          });
        }
      }

      if (!_isMounted) return;

      setState(() {
        farmerList = farmers;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('tbl_user')
              .where('uid', isEqualTo: userId)
              .limit(1)
              .get();
      if (_isMounted && querySnapshot.docs.isNotEmpty) {
        setState(() {
          name = querySnapshot.docs.first['name'];
        });
        print(name);
      } else if (_isMounted) {
        setState(() {
          name = 'Error Loading Data';
        });
      }
    } catch (e) {
      print(e);
      if (_isMounted) {
        setState(() {
          name = 'Error Loading Data';
        });
      }
    }
  }

  Future<void> fetchDistrict() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await db.collection('tbl_district').get();

      List<Map<String, dynamic>> dist = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'district': doc['district_name'].toString(),
              })
          .toList();
      setState(() {
        district = dist;
      });
    } catch (e) {
      print('Error fetching department data: $e');
    }
    print("District: $district");
  }

  Future<void> fetchFPlace(String id) async {
    place = [];
    try {
      selectplace = null;
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection('tbl_place')
          .where('district_id', isEqualTo: id)
          .get();
      List<Map<String, dynamic>> plc = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'place': doc['place_name'].toString(),
              })
          .toList();
      setState(() {
        place = plc;
      });
    } catch (e) {
      print(e);
    }
    print("Place: $place");
  }

  Future<void> handleSearch() async {
    try {
      List<Map<String, dynamic>> farmers = [];

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tbl_farmer')
          .where('place_id', isEqualTo: selectplace)
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        String name = doc['farmer_name'];
        String photo = doc['farmer_photo'];

        Map<String, String>? placeData = await fetchPlace(doc['place_id']);

        if (placeData != null) {
          farmers.add({
            'id': doc.id,
            'name': name,
            'photo': photo,
            'place': placeData,
          });
        }
      }

      if (!_isMounted) return;

      setState(() {
        farmerList = farmers;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
    // Perform search or any other action based on selected values
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Handle side button press
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color.fromARGB(255, 216, 207, 207),
              backgroundImage: AssetImage('assets/logo.webp'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/261.jpg'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50.0),
                      bottomRight: Radius.circular(50.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Explore Varieties',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Welcome $name',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10), // Add space between the texts
                  const Text(
                    'FARMER HUB', // Add your additional text here
                    style: TextStyle(
                      fontSize: 20, // Adjust the font size as needed
                      color: Color.fromARGB(
                          255, 157, 233, 70), // Adjust the color as needed
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 350,
                    child: DropdownButtonFormField<String>(
                      value: selectdistrict,
                      items: district.map<DropdownMenuItem<String>>(
                        (Map<String, dynamic> dist) {
                          return DropdownMenuItem<String>(
                            value: dist['id'],
                            child: Text(
                              dist['district'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectdistrict = value!;
                          fetchFPlace(value);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      isExpanded: true,
                      itemHeight: 50,
                      dropdownColor: Colors.white,
                      elevation: 2,
                      iconSize: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 350,
                    child: DropdownButtonFormField<String>(
                      value: selectplace,
                      items: place.map<DropdownMenuItem<String>>(
                        (Map<String, dynamic> place) {
                          return DropdownMenuItem<String>(
                            value: place['id'],
                            child: Text(
                              place['place'],
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectplace = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Place',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      isExpanded: true,
                      itemHeight: 50,
                      dropdownColor: Colors.white,
                      elevation: 2,
                      iconSize: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: handleSearch,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 129, 238, 133)),
                        ),
                        child: const Text('Search'),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _progressDialog.show();
                          fetchFarmers();
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 129, 238, 133)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.8,
              ),
              itemCount: farmerList.length,
              itemBuilder: (BuildContext context, int index) {
                var farmer = farmerList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FarmerPage(id: farmer['id']),
                        ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: const RoundedRectangleBorder(),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Image.network(farmer[
                              'photo']), // Assuming 'photo' contains the URL of farmer's photo
                          ListTile(
                            title: Text(farmer[
                                'name']), // Assuming 'name' contains the farmer's name
                            subtitle: Text(farmer['place'][
                                'place']), // Assuming 'place' contains the place details
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Order',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 243, 103, 61),
        unselectedItemColor: const Color.fromARGB(255, 243, 103, 61),
        onTap: (int index) {
          switch (index) {
            case 0:
              // Handle home navigation
              break;
            case 1:
              // Navigate to cart screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
              break;
            case 2:
              // Navigate to order screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
