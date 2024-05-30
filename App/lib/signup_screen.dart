import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = true;
  XFile? _selectedImage;
  String? _imageUrl;
  String? filePath;
  String? selectedGender;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _contactcontroller=TextEditingController();
  TextEditingController _passController = TextEditingController();
  List<Map<String, dynamic>> district = [];
  List<Map<String, dynamic>> place = [];
  FirebaseFirestore db = FirebaseFirestore.instance;
  late ProgressDialog _progressDialog;

  @override
  void initState() {
    super.initState();
    fetchDistrict();
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
  }

  Future<void> fetchPlace(String id) async {
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
  }

  Future<void> _registerUser() async {
    _progressDialog.show();
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passController.text,
      );

      await _storeUserData(userCredential.user!.uid);
      _progressDialog.hide();
      Navigator.pop(context);
    } catch (e) {
      _progressDialog.hide();
      print("Error registering user: $e");
    }
  }

  Future<void> _storeUserData(String userId) async {
    try {
      await db.collection('tbl_user').add({
        'uid': userId,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'contact':_contactcontroller.text,
        'place': selectplace,
        'gender': selectedGender,
      
        // Add more fields as needed
      });

      await _uploadImage(userId);
    } catch (e) {
      print("Error storing user data: $e");
    }
  }

  Future<void> _uploadImage(String userId) async {
    try {
      if (_selectedImage != null) {
        final Reference ref = FirebaseStorage.instance
            .ref()
            .child('User/User_Photo/$userId.jpg');
        await ref.putFile(File(_selectedImage!.path));
        final imageUrl = await ref.getDownloadURL();

        await db.collection('tbl_user')
            .where('uid', isEqualTo: userId) // Use 'uid' instead of 'user_id'
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) async {
            await doc.reference.update({
              'image': imageUrl,
            });
          });
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = XFile(pickedFile.path);
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          filePath = result.files.single.path;
        });
      } else {
        // User canceled file picking
        print('File picking canceled.');
      }
    } catch (e) {
      // Handle exceptions
      print('Error picking file: $e');
    }
  }

  String? selectdistrict;
  String? selectplace;

  @override
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Set Scaffold background color to transparent
      body: Container(
        decoration: BoxDecoration(
          // Use a BoxDecoration with a DecorationImage for background image
          image: DecorationImage(
            image: AssetImage('assets/cartoon.jpg'), // Replace 'assets/background_image.jpg' with your image path
            fit: BoxFit.cover, // Adjust the BoxFit as needed
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xff4c505b),
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : _imageUrl != null
                            ? NetworkImage(_imageUrl!)
                            : const AssetImage('assets/dummy.webp')
                                as ImageProvider,
                    child: _selectedImage == null && _imageUrl == null
                        ? const Icon(
                            Icons.add,
                            size: 40,
                            color: Color.fromARGB(255, 134, 134, 134),
                          )
                        : null,
                  ),
                  if (_selectedImage != null || _imageUrl != null)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickFile,
                        child: const Text('Upload File'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filePath != null)
                  Text(
                    'Selected File: $filePath',
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Full name';
                }
                return null;
              },
              decoration: InputDecoration(
              
                hintText: 'Enter Full Name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _dobController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Date of Birth';
                }
                return null;
              },
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'DOB',
                hintText: 'Enter Date of Birth',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gender: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        activeColor: Colors.blue,
                        value: 'Male',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                      const Text('Male', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        activeColor: Colors.blue,
                        value: 'Female',
                        groupValue: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                      const Text('Female', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Email';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectdistrict,
              decoration: InputDecoration(
                
                hintText: 'Select District',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectdistrict = newValue;
                  fetchPlace(newValue!);
                });
              },
              isExpanded: true,
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
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectplace,
              decoration: InputDecoration(
                labelText: 'Place',
                hintText: 'Select Place',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectplace = newValue;
                });
              },
              isExpanded: true,
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
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _addressController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Address';
                }
                return null;
              },
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Enter Address',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 15),
            TextFormField(
              controller:_contactcontroller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact';
                }
                return null;
              },
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'contact',
                hintText: 'Enter contact',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _passController,
              obscureText: true,
              obscuringCharacter: '*',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Password';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
 ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formSignupKey.currentState!.validate() &&
                      agreePersonalData) {
                    _registerUser();
                  } else if (!agreePersonalData) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please agree to the processing of personal data')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Sign up'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}