import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../simple_functions/botton.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EdidProfile extends StatefulWidget {
  const EdidProfile({super.key});

  @override
  State<EdidProfile> createState() => _EdidProfileState();
}

class _EdidProfileState extends State<EdidProfile> {
  String _selectedGender = 'Male';
  String _selectedCountry = 'Amman';
  final _countryMenuController = MenuController();
  final _genderMenuController = MenuController();
  File? _imageFile;
  final List<String> _jordanGovernorates = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Balqa',
    'Madaba',
    'Karak',
    'Tafilah',
    "Ma'an",
    'Aqaba',
    'Mafraq',
    'Jerash',
    'Ajloun'
  ];

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print("No image selected.");
      return null;
    }
  }

  Future<void> updateFirestoreProfilePicture(
      String userId, String newImageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profilePictureUrl': newImageUrl,
      });
      print("Firestore updated successfully.");
    } catch (e) {
      print("Error updating Firestore: $e");
      throw e;
    }
  }

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Map<String, dynamic>? _userData;

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_userData?['uid']}');
      await storageRef.putFile(File(pickedFile.path));
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userData?['uid'])
          .update({'imageUrl': imageUrl});

      setState(() {
        _userData?['imageUrl'] = imageUrl;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _fullNameController.text = _userData!['fullName'] ?? '';
          _usernameController.text = _userData!['username'] ?? '';
          _emailController.text = _userData!['email'] ?? '';
          _phoneController.text = _userData!['phone'] ?? '';
          _addressController.text = _userData!['address'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const textFieldStyle = TextStyle(
      fontSize: 14,
      color: Color.fromARGB(250, 51, 62, 58),
    );

    const labelStyle = TextStyle(
      fontSize: 12,
      color: Color(0xff54826D),
    );

    BoxDecoration textFieldDecoration = BoxDecoration(
      color: const Color.fromARGB(250, 226, 226, 226),
      border: Border.all(
        color: const Color.fromARGB(250, 5, 35, 22),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(7),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(250, 226, 226, 226),
          offset: Offset(0, 4),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Color.fromARGB(250, 179, 185, 183),
          offset: Offset(0, 6),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xffECECEC),
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: const Color(0xffECECEC),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 0),
          child: Stack(
            children: [
              Positioned(
                bottom: -15,
                child: Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 25,
                    height: 15,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xffECECEC),
                          blurRadius: 6.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xff002114),
                  size: 40,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: 1),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xff002114),
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Color.fromARGB(250, 202, 202, 202),
                    offset: Offset(0.0, 5.0),
                  ),
                ],
              ),
            ),
            Spacer(flex: 2),
          ],
        ),
        centerTitle: false,
        titleSpacing: 0.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: textFieldDecoration,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 5, bottom: 5),
                  child: TextField(
                    controller: _fullNameController,
                    style: textFieldStyle,
                    decoration: InputDecoration(
                      hintText: 'Asri Allaham',
                      hintStyle: textFieldStyle.copyWith(color: Colors.grey),
                      labelText: 'Full name',
                      labelStyle: labelStyle,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: textFieldDecoration,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 5, bottom: 5),
                  child: TextField(
                    controller: _usernameController,
                    style: textFieldStyle,
                    decoration: InputDecoration(
                      hintText: 'Asri',
                      hintStyle: textFieldStyle.copyWith(color: Colors.grey),
                      labelText: 'Nick name',
                      labelStyle: labelStyle,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: textFieldDecoration,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 5, bottom: 5),
                  child: TextField(
                    controller: _emailController,
                    style: textFieldStyle,
                    decoration: InputDecoration(
                      hintText: 'asri.allaham@gmail.com',
                      hintStyle: textFieldStyle.copyWith(color: Colors.grey),
                      labelText: 'Email',
                      labelStyle: labelStyle,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: textFieldDecoration,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 5, bottom: 5),
                  child: Row(
                    children: [
                      Image.asset(
                        'lib/img/JORDAN.jpg',
                        width: 50,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: textFieldStyle,
                          decoration: InputDecoration(
                            hintText: '+962 787868672',
                            hintStyle:
                                textFieldStyle.copyWith(color: Colors.grey),
                            labelText: 'Phone number',
                            labelStyle: labelStyle,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      margin:
                          const EdgeInsets.only(bottom: 20, top: 10, right: 5),
                      decoration: textFieldDecoration,
                      child: MenuAnchor(
                        controller: _countryMenuController,
                        style: MenuStyle(
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromARGB(250, 226, 226, 226)),
                          elevation: MaterialStateProperty.all(0),
                          surfaceTintColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                              side: BorderSide(
                                color: const Color.fromARGB(250, 5, 35, 22),
                                width: 1,
                              ),
                            ),
                          ),
                          fixedSize: MaterialStateProperty.all(Size.fromHeight(
                              200)), // Fixed height for scrolling
                        ),
                        menuChildren: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    _jordanGovernorates.map((String value) {
                                  return MenuItemButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCountry = value;
                                        _countryMenuController.close();
                                      });
                                    },
                                    child: Text(value, style: textFieldStyle),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                        builder: (BuildContext context,
                            MenuController controller, Widget? child) {
                          return InkWell(
                            onTap: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedCountry, style: textFieldStyle),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      margin:
                          const EdgeInsets.only(bottom: 20, top: 10, left: 5),
                      decoration: textFieldDecoration,
                      child: MenuAnchor(
                        controller: _genderMenuController,
                        style: MenuStyle(
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromARGB(250, 226, 226, 226)),
                          elevation: MaterialStateProperty.all(0),
                          surfaceTintColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                              side: BorderSide(
                                color: const Color.fromARGB(250, 5, 35, 22),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        menuChildren: ['Male', 'Female'].map((String value) {
                          return MenuItemButton(
                            onPressed: () {
                              setState(() {
                                _selectedGender = value;
                                _genderMenuController.close();
                              });
                            },
                            child: Text(value, style: textFieldStyle),
                          );
                        }).toList(),
                        builder: (BuildContext context,
                            MenuController controller, Widget? child) {
                          return InkWell(
                            onTap: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_selectedGender, style: textFieldStyle),
                                  const Icon(Icons.arrow_drop_down),
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
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 30, top: 10),
                decoration: textFieldDecoration,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 5, bottom: 5),
                  child: TextField(
                    controller: _addressController,
                    style: textFieldStyle,
                    decoration: InputDecoration(
                      hintText: 'Amman, Jordan',
                      hintStyle: textFieldStyle.copyWith(color: Colors.grey),
                      labelText: 'Address',
                      labelStyle: labelStyle,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: _pickAndUploadProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _userData?['imageUrl'] != null
                      ? NetworkImage(_userData!['imageUrl'])
                      : null,
                  child: _userData?['imageUrl'] == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              GradientButton(
                text: "Submit",
                onTap: () async {
                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('No user is currently logged in.')),
                      );
                      return;
                    }

                    final updatedData = {
                      'fullName': _fullNameController.text.trim(),
                      'username': _usernameController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'address': _addressController.text.trim(),
                    };

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update(updatedData);

                    setState(() {
                      _userData = {
                        ...?_userData,
                        ...updatedData,
                      };
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile.')),
                    );
                  }
                },
                width: double.infinity,
              )
            ],
          ),
        ),
      ),
    );
  }
}
