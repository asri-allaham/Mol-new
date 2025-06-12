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

  String? searchQuery;
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> filteredProjects = [];
  bool _isLoading = true;
  Map<String, dynamic>? selectedProject;

  final user = FirebaseAuth.instance.currentUser;

  bool isLoading = false;
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

  @override
  void initState() {
    super.initState();
    badWordsSoundex = {for (var w in badWords) w: soundex(w)};
    fetchProjectsAndOwners();
  }

  Future<void> fetchProjectsAndOwners() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = await query.where('user_id', isEqualTo: user!.uid).get();

      List<Map<String, dynamic>> loadedProjects = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();
        final adminAccepted = projectData['Adminacceptance'] ?? false;

        if (adminAccepted != true) {
          continue;
        }

        loadedProjects.add({
          'id': doc.id,
          ...projectData,
        });
      }

      setState(() {
        projects = loadedProjects;
        filteredProjects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching projects: $e');
    }
  }

  void filterProjects(String query) {
    List<Map<String, dynamic>> tempList = projects.where((project) {
      final name = project['name']?.toString().toLowerCase() ?? '';
      final description =
          project['description']?.toString().toLowerCase() ?? '';
      final search = query.toLowerCase();

      // Filter by name OR description containing the query
      return name.contains(search) || description.contains(search);
    }).toList();

    setState(() {
      filteredProjects = tempList;
      selectedProject = null;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (_selectedImages.length < 6) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 6 images allowed')),
        );
      }
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload.')),
      );
      return;
    }

    if (_selectedImages.isEmpty ||
        _projectNameController.text.isEmpty ||
        _projectDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select images and enter post name and description.')),
      );
      return;
    }

    if (selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project.')),
      );
      return;
    }

    if (containsBadWordsInNameOrDescription(
        _projectNameController.text, _projectDescriptionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post contains inappropriate words.')),
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
    int postNumber = await getNextPostNumberForUser(user?.uid);

    await FirebaseFirestore.instance.collection('post').add({
      'Adminacceptance': false,
      'user_id': user?.uid ?? 'unknown',
      'name': _projectNameController.text.trim(),
      'description': _projectDescriptionController.text.trim(),
      'image_urls': imageUrls,
      'created_at': FieldValue.serverTimestamp(),
      'postNumber': postNumber,
      'projectNumber': selectedProject!['projectNumber']
    });
  }

  Future<int> getNextPostNumberForUser(String? userId) async {
    final counterDoc =
        FirebaseFirestore.instance.collection('post').doc(userId);

    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterDoc);
      int current = 0;
      if (snapshot.exists) {
        current = snapshot.get('postNumber') as int;
      }
      final next = current + 1;
      transaction.set(counterDoc, {'postNumber': next});
      return next;
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
                        'Project Name',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _projectNameController,
                        maxLength: 35,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                          hintText: 'Enter the post name',
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Project Description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _projectDescriptionController,
                        maxLength: 50,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                          hintText: 'Enter the post description',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search projects to select',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (value) {
                  filterProjects(value);
                },
              ),
              const SizedBox(height: 10),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProjects.isEmpty
                        ? const Center(child: Text('No projects found'))
                        : ListView.builder(
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              final isSelected = selectedProject != null &&
                                  selectedProject!['id'] == project['id'];
                              return ListTile(
                                tileColor:
                                    isSelected ? Colors.green.shade100 : null,
                                title: Text(
                                  project['name'] ?? 'Unnamed Project',
                                  style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                                subtitle: Text(
                                  project['description'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedProject = project;
                                  });
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._selectedImages.map((imageFile) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            imageFile,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedImages.remove(imageFile);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _uploadImageToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2F7E43),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Upload Post',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
