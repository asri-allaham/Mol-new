import 'package:Mollni/Dartpages/Admin/AdminTapsSystem.dart';
import 'package:Mollni/Dartpages/Communicate%20with%20investor/business%20owners/messages_page.dart';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/HomePage/favorites.dart';
import 'package:Mollni/Dartpages/UserData/Notifications/Notifications.dart';
import 'package:Mollni/Dartpages/UserData/Settings.dart';
import 'package:Mollni/Dartpages/project%20post%20Contracts/TapsSystem.dart';
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
  int _selectedIndex = 3;

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
    bool isadmin = false;
    if (_userData?['admin'] == true) isadmin = true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffE4F5ED),
        automaticallyImplyLeading: false,
        toolbarHeight: 30,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                SizedBox(width: 17),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => Favorites()));
                      },
                      icon: Icon(Icons.favorite,
                          size: 35, color: Color.fromARGB(255, 182, 23, 23)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    if (user?.uid == null) {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    } else {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => settings()));
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
      body: Column(
        children: [
          Expanded(
            child: _userData == null
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
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundImage: _userData!['imageUrl'] !=
                                            null
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
                            ],
                          ),
                        ],
                      ),
                      _buildInfoSection("nick Name", _userData?['nickName']),
                      _buildInfoSection("full Name", _userData?['fullName']),
                      _buildInfoSection("Email Address", _userData?['email']),
                      _buildInfoSection("Address", _userData?['address']),
                      _buildInfoSection("Phone Number", _userData?['phone']),
                      const SizedBox(height: 40),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xff54826D),
                    Color(0xff03361F),
                    Color(0xff03361F),
                    Color(0xff03361F),
                    Color(0xff03361F)
                  ],
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
                  if (isadmin) ...[
                    _buildNavItem(Icons.admin_panel_settings, 1),
                  ] else
                    _buildNavItem(Icons.add, 1),
                  _buildNavItem(Icons.message, 2),
                  _buildNavItem(Icons.person, 3),
                ],
              ),
            ),
          ),
        ],
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
    String getTruncatedValue(String? input, {int maxLength = 20}) {
      final text = input ?? 'Not provided';
      if (text.length > maxLength) {
        return '${text.substring(0, maxLength)}...';
      }
      return text;
    }

    return Row(
      children: [
        const SizedBox(width: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 23),
            Text(
              title,
              style: const TextStyle(color: Color(0xff54826D), fontSize: 18),
            ),
            Row(
              children: [
                const SizedBox(width: 6, height: 35),
                Text(
                  getTruncatedValue(value),
                  style:
                      const TextStyle(color: Color(0xff012113), fontSize: 24),
                )
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Widget getPageForIndex(int index) {
          if (index == 0) {
            if (user != null) {
              return Homepage();
            }
          } else if (index == 1) {
            if (user != null && (_userData?['admin'] ?? false)) {
              return Admintapssystem(projects, posts);
            }
            return user != null ? BottomTabs() : const LoginPage();
          } else if (index == 2) {
            return user != null ? MessagesPage() : const LoginPage();
          } else if (index == 3) {
            return user != null ? Profile() : const LoginPage();
          }
          return SizedBox();
        }

        final page = getPageForIndex(_selectedIndex);
        if (page is! SizedBox) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Icon(icon,
          color: _selectedIndex == index ? Colors.white : Colors.white70),
    );
  }
}
