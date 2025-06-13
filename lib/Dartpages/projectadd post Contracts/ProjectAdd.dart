import 'dart:io';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final List<String> badWords = [
    'damn',
    'hell',
    'crap',
    'shit',
    'fuck',
    'bitch',
    'asshole',
    'bastard',
    'dick',
    'piss',
    'darn',
    'cock',
    'pussy',
    'fag',
    'slut',
    'whore',
    'nigger',
    'cunt',
    'bollocks',
    'bugger',
    'bloody',
    'arse',
    'twat',
    'prick',
    'motherfucker',
    'son of a bitch',
    'goddamn',
    'dammit',
    'shithead',
    'douche',
    'jerk',
    'crappy',
    'fucker',
    'wanker',
    'chink',
    'spic',
    'retard',
    'kike',
    'dyke',
    'slutty',
    'twat',
    'shitface',
    'faggy',
    'ass',
    'bimbo',
    'shitbag',
    'douchebag'
  ];
  late final Map<String, String> badWordsSoundex;

  String soundex(String s) {
    if (s.isEmpty) return "";

    final Map<String, String> codes = {
      'b': '1',
      'f': '1',
      'p': '1',
      'v': '1',
      'c': '2',
      'g': '2',
      'j': '2',
      'k': '2',
      'q': '2',
      's': '2',
      'x': '2',
      'z': '2',
      'd': '3',
      't': '3',
      'l': '4',
      'm': '5',
      'n': '5',
      'r': '6',
    };

    String upper = s.toLowerCase();
    String firstLetter = upper[0].toUpperCase();
    StringBuffer output = StringBuffer(firstLetter);

    String lastCode = codes[upper[0]] ?? '';
    int count = 1;

    for (int i = 1; i < upper.length && count < 4; i++) {
      String c = upper[i];
      if (!codes.containsKey(c)) continue;
      String code = codes[c]!;

      if (code != lastCode) {
        output.write(code);
        lastCode = code;
        count++;
      }
    }

    while (output.length < 4) {
      output.write('0');
    }

    return output.toString();
  }

  @override
  void initState() {
    super.initState();
    badWordsSoundex = {for (var w in badWords) w: soundex(w)};
  }

  bool containsBadWord(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));

    for (var word in words) {
      if (badWords.contains(word)) {
        return true;
      }
    }
    return false;
  }

  bool containsBadWordsInNameOrDescription(String name, String description) {
    return containsBadWord(name) || containsBadWord(description);
  }

  final List<String> _categories = [
    'Technology',
    'Health',
    'Education',
    'Finance',
    'Other'
  ];

  bool isLoading = false;

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
            content: Text('Please select images and enter a project name.')),
      );
      return;
    }
    if (containsBadWordsInNameOrDescription(
        _projectNameController.text, _projectDescriptionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project contains inappropriate words.')),
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
    int projectNumber = await getNextProjectNumberForUser(user?.uid);

    await FirebaseFirestore.instance.collection('projects').add({
      'user_id': user?.uid ?? 'unknown',
      'name': _projectNameController.text.trim(),
      'investment_amount':
          double.tryParse(_investmentAmountController.text.trim()) ?? 0,
      'description': _projectDescriptionController.text.trim(),
      'category': _selectedCategory ?? 'Uncategorized',
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
      'projectNumber': projectNumber
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
          "Add Project",
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
                        "Upload Project Images",
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
                        "Project Details",
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
                          labelText: "Project Name",
                          labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _investmentAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: "Investment Amount",
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
                          labelText: "Project Description",
                          labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          labelText: "Category",
                          labelStyle: const TextStyle(color: Color(0xff2F7E43)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
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
                  : ElevatedButton(
                      onPressed: isLoading ? null : _uploadImageToFirebase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2F7E43),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Upload to Firebase",
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

  Future<int> getNextProjectNumberForUser(String? userId) async {
    if (userId == null) return 0;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('user_id', isEqualTo: userId)
        .get();

    int projectCount = querySnapshot.docs.length;
    return projectCount + 1;
  }
}
