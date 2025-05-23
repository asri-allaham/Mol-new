import 'package:MOLLILE/Dartpages/CustomWidget/SearchBox.dart';
import 'package:MOLLILE/Dartpages/HomePage/ProjectAdd.dart';
import 'package:MOLLILE/Dartpages/UserData/profile_information.dart';
import 'package:MOLLILE/Dartpages/sighUpIn/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Communicate with investor/business owners/masseges.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<String> categories = [
    'Technology',
    'Health',
    'Education',
    'Art',
    'Finance',
    'Other'
  ];

  int _currentPopularImageIndex = 0;
  int _currentInvestmentImageIndex = 0;
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchProjectsAndOwners();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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

  Future<void> fetchProjectsAndOwners([String? category]) async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = category == null
          ? await query.get()
          : await query.where('category', isEqualTo: category).get();

      List<Map<String, dynamic>> loadedProjects = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();
        final userId = projectData['user_id'];
        userFutures.add(
          FirebaseFirestore.instance.collection('users').doc(userId).get(),
        );
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < snapshot.docs.length; i++) {
        final projectData = snapshot.docs[i].data();
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['urlImage'] ?? ''
            : '';

        loadedProjects.add({
          'user_id': projectData['user_id'],
          'name': projectData['name'],
          'description': projectData['description'],
          'image_urls': projectData['image_urls'],
          'investment_amount': projectData['investment_amount'],
          'category': projectData['category'],
          'created_at': projectData['created_at'],
          'owner_image': ownerImage,
        });
      }

      setState(() {
        projects = loadedProjects;
        _isLoading = false;
      });

      print("✅ Projects for category '${category ?? "All"}' loaded!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error fetching projects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xffECECEC),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 166, bottom: 60),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                if (projects.isNotEmpty)
                  _buildSectionTitle("the_most_popular".tr()),
                const SizedBox(height: 12),
                _buildImageSlider(
                  projects,
                  _currentPopularImageIndex,
                  (index) {
                    setState(() {
                      _currentPopularImageIndex = index;
                    });
                  },
                ),
                _buildInfoRow(_currentPopularImageIndex, projects.length),
                const SizedBox(height: 30),
                if (projects.isNotEmpty)
                  _buildSectionTitle("highest_investment".tr()),
                const SizedBox(height: 12),
                _buildImageSlider(
                  projects,
                  _currentInvestmentImageIndex,
                  (index) {
                    setState(() {
                      _currentInvestmentImageIndex = index;
                    });
                  },
                ),
                _buildInfoRow(_currentInvestmentImageIndex, projects.length),
                const SizedBox(height: 30),
              ],
            ),
          ),
          _buildHeader(),
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
                    Color(0xff03361F),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const SizedBox(width: 23),
        Text(
          title,
          style: const TextStyle(fontSize: 18, color: Color(0xff012113)),
        ),
        const Spacer(),
        Text(
          "view_all".tr(),
          style: const TextStyle(fontSize: 15, color: Color(0xff54826D)),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildImageSlider(List<Map<String, dynamic>> projectList,
      int currentIndex, Function(int) onChanged) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: projectList.length > 3 ? 3 : projectList.length,
        onPageChanged: onChanged,
        itemBuilder: (context, index) {
          // final imageUrlList = projectList[index]['image_urls'];
          // final imageUrl = (imageUrlList is List && imageUrlList.isNotEmpty)
          //     ? imageUrlList[0]
          //     : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: ClipOval(
                      child: projects[index]['owner_image'] != null &&
                              projects[index]['owner_image'] != ''
                          ? Image.network(
                              projects[index]['owner_image'],
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            )
                          : Image.asset(
                              'lib/img/person1.png',
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(int currentIndex, int totalImages) {
    if (projects.isEmpty) {
      return Center(child: Text("no_projects_found".tr()));
    }

    if (currentIndex < 0 || currentIndex >= projects.length) {
      return Center(child: Text("invalid_project_index".tr()));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projects[currentIndex]['name'],
                style: const TextStyle(fontSize: 15, color: Color(0xff000000)),
              ),
              // Text( no need
              //   projects[currentIndex]['description'],
              //   style: const TextStyle(fontSize: 15, color: Color(0xff000000)),
              // ),
            ],
          ),
          const SizedBox(width: 50),
          Row(
            children: List.generate(totalImages, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? const Color(0xff012113)
                      : const Color(0xffD9D9D9),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
          const Spacer(),
          Text(
            "75%", // You may want to calculate this based on data
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          tileMode: TileMode.mirror,
          colors: [
            Color(0xff03361F),
            Color(0xff03361F),
            Color(0xff03361F),
            Color(0xff54826D)
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 0, right: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: GestureDetector(
                      onTap: () {
                        if (FirebaseAuth.instance.currentUser != null) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  const ProfileInformation()));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                        }
                      },
                      child: Image.asset('lib/img/person1.png'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InkWell(
              onTap: () {},
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child:
                        Image.asset('lib/img/logo.png', height: 28, width: 28),
                  ),
                  CustomSearchBox(hintText: "search_here".tr()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 24,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(6, (index) {
                return InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Image.asset('lib/img/img_${index + 1}.png',
                        width: 26, height: 24),
                  ),
                  onTap: () {
                    String selectedCategory = categories[index];
                    setState(() {
                      _isLoading = true;
                    });
                    fetchProjectsAndOwners(selectedCategory);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        if (_selectedIndex == 1) {
          if (user != null) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProjectAdd()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 2) {
          if (user != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => MessagesPage()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 3) {
          if (user != null) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileInformation()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        }
      },
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
