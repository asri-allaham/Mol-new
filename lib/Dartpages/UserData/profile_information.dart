import 'package:Mollni/Dartpages/UserData/Settings.dart';
import 'package:Mollni/Dartpages/sighUpIn/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _MyProfile();
}

class _MyProfile extends State<Profile> {
  User? user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> projects = [], posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
    user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  Future<void> fetchProjectsAndOwners() async {
    if (user == null) return; // Avoid null crash

    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = await query.where('user_id', isEqualTo: user!.uid).get();

      List<Map<String, dynamic>> loadedProjects = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();

        final adminAccepted = projectData['Adminacceptance'] ?? false;
        final hasImage = projectData['image_urls'] != null &&
            projectData['image_urls'].isNotEmpty;

        if (adminAccepted && hasImage) {
          loadedProjects.add(projectData);
        }
      }

      setState(() {
        projects = loadedProjects;
        _isLoading = false;
      });

      print("✅ Loaded ${projects.length} approved projects with images");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching projects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffE4F5ED),
        automaticallyImplyLeading: false,
        toolbarHeight: 30,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xff012113),
              ),
            ),
            Row(
              children: [
                Icon(Icons.notifications,
                    color: const Color.fromARGB(255, 49, 90, 54), size: 30),
                IconButton(
                  onPressed: () {
                    if (user?.uid == null) {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProfileInformation()));
                    }
                  },
                  icon: Icon(Icons.settings,
                      color: const Color.fromARGB(255, 49, 90, 54), size: 30),
                )
              ],
            )
          ],
        ),
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 260,
                      child: Image.asset(
                        "lib/img/profile444.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _userData!['imageUrl'] != null
                                  ? NetworkImage(_userData!['imageUrl'])
                                  : const AssetImage(
                                          'lib/Images/DefaultProfile.jpg')
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        Text(
                          _userData?['fullName'] ?? '',
                          style: const TextStyle(
                              color: Color(0xff012113), fontSize: 20),
                        ),
                        Text(
                          "@${_userData?['username'] ?? ''}",
                          style: const TextStyle(
                              color: Color(0xff012113), fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Spacer(),
                            _buildIcon(Icons.chat),
                            const Spacer(),
                            _buildIcon(Icons.more_horiz, size: 32),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                _buildInfoSection("nick Name", _userData?['username']),
                _buildInfoSection("full Name", _userData?['fullName']),
                _buildInfoSection("Email Address", _userData?['email']),
                _buildInfoSection("Address", _userData?['address']),
                _buildInfoSection("Phone Number", _userData?['phone']),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Text("Business ideas",
                        style:
                            TextStyle(color: Color(0xff54826D), fontSize: 17)),
                    SizedBox(width: MediaQuery.of(context).size.width / 2.3),
                    const Text("View All",
                        style:
                            TextStyle(color: Color(0xff012C19), fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Projects",
                              style: TextStyle(
                                  color: Color(0xff54826D), fontSize: 17)),
                          Text("View All",
                              style: TextStyle(
                                  color: Color(0xff012C19), fontSize: 17)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: projects.isEmpty
                          ? const Center(child: Text("No projects to display"))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: projects.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 15),
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                final imageUrl = project['image_urls']
                                    [0]; // First image only
                                return _buildIdeaImageFromUrl(imageUrl);
                              },
                            ),
                    ),
                  ],
                )
              ],
            ),
    );
  }

  Widget _buildIdeaImageFromUrl(String imageUrl) {
    return Container(
      width: 106,
      height: 109,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, {double size = 28}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: const Color(0xff012113),
          borderRadius: BorderRadius.circular(100)),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildInfoSection(String title, String? value) {
    return Row(
      children: [
        const SizedBox(width: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 23),
            Text(title,
                style: const TextStyle(color: Color(0xff54826D), fontSize: 18)),
            Row(
              children: [
                const SizedBox(width: 6, height: 35),
                Text(
                  value ?? 'Not provided',
                  style:
                      const TextStyle(color: Color(0xff012113), fontSize: 24),
                )
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildIdeaImage(String assetPath) {
    return Container(
      width: 106,
      height: 109,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
