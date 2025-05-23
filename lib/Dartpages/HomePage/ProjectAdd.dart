import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home_page.dart';

class ProjectAdd extends StatefulWidget {
  const ProjectAdd({super.key});

  @override
  State<ProjectAdd> createState() => _ImageUploaderPageState();
}

class _ImageUploaderPageState extends State<ProjectAdd> {
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _investmentAmountController =
      TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = [
    'Technology',
    'Health',
    'Education',
    'Finance',
    'Other'
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }

    try {
      List<String> downloadUrls = [];

      for (var imageFile in _selectedImages) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'project_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}');

        await storageRef.putFile(imageFile);
        final downloadUrl = await storageRef.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      await _saveProjectDetailsToFirestore(downloadUrls);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload and save successful!')),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      }
    } catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _saveProjectDetailsToFirestore(List<String> imageUrls) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('projects').add({
      'user_id': user?.uid ?? 'unknown',
      'name': _projectNameController.text.trim(),
      'investment_amount':
          double.tryParse(_investmentAmountController.text.trim()) ?? 0,
      'description': _projectDescriptionController.text.trim(),
      'category': _selectedCategory ?? 'Uncategorized',
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffDAF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xff2F7E43),
        title: const Text(
          "Add_project",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                try {
                  await _pickImage();
                } catch (e) {
                  print(e);
                }
              },
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xffFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedImages.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(_selectedImages.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImages.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          color: Color(0xff2F7E43),
                          size: 50,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._selectedImages.map((file) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xffFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        color: Color(0xff2F7E43),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                fillColor: Color(0xffFFFFFF),
                filled: true,
                labelText: "Project Name",
                labelStyle: TextStyle(color: Color(0xff2F7E43)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _investmentAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                fillColor: Color(0xffFFFFFF),
                filled: true,
                labelText: 'Investment Amount',
                labelStyle: TextStyle(color: Color(0xff2F7E43)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _projectDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                fillColor: Color(0xffFFFFFF),
                filled: true,
                labelText: 'Project Description',
                labelStyle: TextStyle(color: Color(0xff2F7E43)),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                fillColor: Color(0xffFFFFFF),
                filled: true,
                labelText: 'Category',
                labelStyle: TextStyle(color: Color(0xff2F7E43)),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImageToFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2F7E43),
              ),
              child: const Text("Upload to Firebase"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
