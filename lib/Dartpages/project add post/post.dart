import 'dart:io';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Post extends StatefulWidget {
  const Post({super.key});

  @override
  State<Post> createState() => _ImageUploaderPageState();
}

class _ImageUploaderPageState extends State<Post> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  String? selectedCategory;
  List<String> categories = [];
  List<Map<String, dynamic>> projects = [];
  bool _isLoading = true;
  Map<String, dynamic>? selectedProject;

  final user = FirebaseAuth.instance.currentUser;
  @override
  void initState() {
    super.initState();
    fetchProjectsAndOwners();
  }

  bool isLoading = false;
  Future<void> fetchProjectsAndOwners([String? name]) async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = await query.where('user_id', isEqualTo: user!.uid).get();

      List<Map<String, dynamic>> loadedProjects = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();
        final adminAccepted = projectData['Adminacceptance'] ?? false;

        if (adminAccepted != true) {
          continue;
        }

        if (name != null &&
            !projectData['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase())) {
          continue;
        }

        loadedProjects.add({
          'id': doc.id,
          ...projectData,
        });
      }

      setState(() {
        projects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

    if (_selectedImages.isEmpty || _projectNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select images and enter a post name.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<String> downloadUrls = [];

      for (var imageFile in _selectedImages) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'Post_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}');
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
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProjectDetailsToFirestore(List<String> imageUrls) async {
    final user = FirebaseAuth.instance.currentUser;
    int PostNumber = await getNextPostNumberForUser(user?.uid);

    await FirebaseFirestore.instance.collection('post').add({
      'Adminacceptance': false,
      'user_id': user?.uid ?? 'unknown',
      'name': _projectNameController.text.trim(),
      'description': _projectDescriptionController.text.trim(),
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
      'postNumber': PostNumber,
      'projectNumber': selectedProject!['projectNumber']
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xffDAF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xff2F7E43),
        title: const Text(
          "Make New Post",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload Post Images",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2F7E43),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: screenHeight * 0.25,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: _selectedImages.isNotEmpty
                                ? null
                                : Colors.grey[200],
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
                                    Icons.add_photo_alternate,
                                    color: Color(0xff2F7E43),
                                    size: 60,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _selectedImages.length < 6
                            ? _selectedImages.length + 1
                            : _selectedImages.length,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length &&
                              _selectedImages.length < 6) {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[200],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Color(0xff2F7E43),
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Post Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2F7E43),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _projectNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: "Post Display Name",
                          labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _projectDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: "Post Description",
                          labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff2F7E43),
                      ),
                    )
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedProject,
                      items: projects
                          .map((project) =>
                              DropdownMenuItem<Map<String, dynamic>>(
                                value: project,
                                child:
                                    Text(project['name'] ?? 'Unnamed Project'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProject = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        labelText: "Select your Project...",
                        labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff2F7E43),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (selectedProject != null) {
                          isLoading ? null : _uploadImageToFirebase();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2F7E43),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Ready to Post?",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> getNextPostNumberForUser(String? userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('post')
        .where('user_id', isEqualTo: userId)
        .get();

    return querySnapshot.docs.length + 1;
  }
}
