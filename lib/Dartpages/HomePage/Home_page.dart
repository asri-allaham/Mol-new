import 'package:MOLLILE/Dartpages/Communicate%20with%20investor/messages_page.dart';
import 'package:MOLLILE/Dartpages/CustomWidget/SearchBox.dart';
import 'package:MOLLILE/Dartpages/HomePage/placeholders.dart';
import 'package:MOLLILE/Dartpages/HomePage/viewItems.dart';
import 'package:MOLLILE/Dartpages/UserData/profile_information.dart';
import 'package:MOLLILE/Dartpages/sighUpIn/LoginPage.dart';
import 'package:MOLLILE/project%20add%20post/TapsSystem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<String?> categories = [
    null,
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

  TextEditingController _searchController = TextEditingController();

  User? user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> projects = [];
  bool _isLoading = true;
  String currentPage = "Home";
  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchProjectsAndOwners();
  }

  Future<void> fetchUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
    user = FirebaseAuth.instance.currentUser;
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

  Future<void> fetchProjectsAndOwners([String? category, String? name]) async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = category == null
          ? await query.get()
          : await query.where('category', isEqualTo: category).get();

      List<Map<String, dynamic>> loadedProjects = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();

        if (name != null &&
            !projectData['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase())) {
          continue;
        }

        final userId = projectData['user_id'];
        userFutures.add(
          FirebaseFirestore.instance.collection('users').doc(userId).get(),
        );

        loadedProjects.add(projectData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedProjects.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['urlImage'] ?? ''
            : '';

        loadedProjects[i]['owner_image'] = ownerImage;
      }

      loadedProjects.sort((a, b) {
        int nameCmp = a['name'].compareTo(b['name']);
        if (nameCmp != 0) return nameCmp;
        int descCmp = a['description'].compareTo(b['description']);
        if (descCmp != 0) return descCmp;
        return a['investment_amount'].compareTo(b['investment_amount']);
      });

      setState(() {
        projects = loadedProjects;
        _isLoading = false;
      });

      print("✅ Projects filtered by name '${name ?? "All"}' loaded!");
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (user == null)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    "will be there in no time...",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xffECECEC),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.035, bottom: 60),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                if (projects.isNotEmpty)
                  _buildSectionTitle("the_most_popular".tr()),
                const SizedBox(height: 12),
                _buildImageSlider(projects, _currentPopularImageIndex, (index) {
                  setState(() {
                    _currentPopularImageIndex = index;
                  });
                }, 3),
                _buildInfoRow(_currentPopularImageIndex, projects.length),
                const SizedBox(height: 30),
                if (projects.isNotEmpty)
                  _buildSectionTitle("highest_investment".tr()),
                const SizedBox(height: 12),
                _buildImageSlider(projects, _currentInvestmentImageIndex,
                    (index) {
                  setState(() {
                    _currentInvestmentImageIndex = index;
                  });
                }, 3),
                _buildInfoRow(_currentInvestmentImageIndex, projects.length),
                const SizedBox(height: 30),
                _DisplayItem(),
              ],
            ),
          ),
          //here
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

  Widget _DisplayItem() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (ctx, index) {
        final project = projects[index];
        final imageUrl = (project['image_urls'] as List).isNotEmpty
            ? project['image_urls'][0]
            : null;

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Image.asset('lib/img/placeholder.png',
                          fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  project['name'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
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
        InkWell(
          child: Text(
            "view_all".tr(),
            style: const TextStyle(fontSize: 15, color: Color(0xff54826D)),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text("All Projects"),
                  ),
                  body: Viewitems(projects: projects),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildImageSlider(List<Map<String, dynamic>> projectList,
      int currentIndex, Function(int) onChanged, int length) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: projectList.length > 3 ? length : projectList.length,
        scrollDirection: Axis.horizontal,
        onPageChanged: onChanged,
        itemBuilder: (context, index) {
          final imageUrlList = projectList[index]['image_urls'];
          final imageUrl = (imageUrlList is List && imageUrlList.isNotEmpty)
              ? imageUrlList[0]
              : null;

          final screenWidth = MediaQuery.of(context).size.width;
          final imageSize = screenWidth * 1;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              Placeholders(projectList[index])));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: imageUrl != null && imageUrl != ''
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize,
                            )
                          : Image.asset(
                              'lib/img/placeholder.png',
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize,
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
          // Text(
          //   "75%",
          //   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(width: 50),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InkWell(
              onTap: () {},
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.height * 0.035,
                        top: MediaQuery.of(context).size.height * 0.015),
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/img/logo.png',
                          height: MediaQuery.of(context).size.height * 0.035,
                          width: MediaQuery.of(context).size.height * 0.035,
                        ),
                        user == null
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginPage()),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.height *
                                          0.22),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                  ),
                                ),
                              )
                            : const Text(""),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.height * 0.035,
                        ),
                        child: CustomSearchBox(
                          controller: _searchController,
                          onChanged: (value) {
                            fetchProjectsAndOwners(null, value);
                          },
                          hintText: "Search by project name",
                          width: MediaQuery.of(context).size.height * 0.25,
                        ),
                      ),
                    ],
                  )
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
                    padding: EdgeInsets.only(
                      right: MediaQuery.of(context).size.height * 0.01,
                    ),
                    child: Container(
                      width: 60,
                      child: Center(
                        child: Image.asset(
                          'lib/img/img_${index + 1}.png',
                          width: 26,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    String? selectedCategory = categories[index];
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
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => BottomTabs()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 2) {
          if (user != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MessagesPage()),
            );
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
