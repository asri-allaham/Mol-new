import 'dart:math';

import 'package:Mollni/Dartpages/Communicate%20with%20investor/business%20owners/messages_page.dart';
import 'package:Mollni/Dartpages/CustomWidget/SearchBox.dart';
import 'package:Mollni/Dartpages/HomePage/placeholders.dart';
import 'package:Mollni/Dartpages/HomePage/viewItems.dart';
import 'package:Mollni/Dartpages/UserData/Settings.dart';
import 'package:Mollni/Dartpages/UserData/profile_information.dart';
import 'package:Mollni/Dartpages/projectadd%20post%20Contracts/TapsSystem.dart';
import 'package:Mollni/Dartpages/sighUpIn/LoginPage.dart';
import 'package:Mollni/simple_functions/star_menu_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Mollni/Dartpages/Admin/AdminTapsSystem.dart';

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
  final List<String> investmentMessages = [
    "Analyzing stocks...",
    "Building your empire...",
    "Loading assets...",
    "Scanning markets...",
    "Getting insights...",
    "Smart moves ahead...",
    "Optimizing growth...",
    "Risk check...",
    "Preparing tools...",
    "Wealth loading..."
  ];

  int _currentPopularImageIndex = 0;
  int _currentInvestmentImageIndex = 0;
  int _selectedIndex = 0;
  String? fcmToken;

  TextEditingController _searchController = TextEditingController();

  User? user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> projects = [], posts = [];
  bool _isLoading = true;
  String currentPage = "Home";

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchProjectsAndOwners();
    fetchPostsAndOwners();
    _saveFcmToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'fcmToken': newToken});
    });
  }

  Future<void> fetchUserData() async {
    try {
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
    } catch (e) {
      print(e);
    }
  }

  Map<String, dynamic>? getProjectFromLocalList(
      String userId, int projectNumber) {
    try {
      return projects.firstWhere(
          (project) =>
              project['user_id'] == userId &&
              project['projectNumber'] == projectNumber,
          orElse: () => {});
    } catch (e) {
      print('Error finding project locally: $e');
      return null;
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

        final adminAccepted = projectData['Adminacceptance'] ?? false;
        final removed = projectData['removed'] == true;

        if (adminAccepted != true || removed) {
          continue;
        }

        if (name != null &&
            !projectData['name']
                .toString()
                .toLowerCase()
                .contains(name.toLowerCase())) {
          continue;
        }

        final userId = projectData['user_id'];
        userFutures.add(
            FirebaseFirestore.instance.collection('users').doc(userId).get());

        loadedProjects.add(projectData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedProjects.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['imageUrl'] ?? ''
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

  Future<void> fetchPostsAndOwners([String? category, String? name]) async {
    try {
      final query = FirebaseFirestore.instance.collection('post');
      final snapshot = await query.get();
      List<Map<String, dynamic>> loadedPosts = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final postsData = doc.data();
        final userId = postsData['user_id'];
        final adminAccepted = postsData['Adminacceptance'] ?? false;
        final removed = postsData['removed'] == true;

        if (adminAccepted != true || removed) {
          continue;
        }
        userFutures.add(
            FirebaseFirestore.instance.collection('users').doc(userId).get());

        loadedPosts.add(postsData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedPosts.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['imageUrl'] ?? ''
            : '';

        loadedPosts[i]['owner_image'] = ownerImage;
      }

      loadedPosts.sort((a, b) {
        int nameCmp = a['name'].compareTo(b['name']);
        if (nameCmp != 0) return nameCmp;
        int descCmp = a['description'].compareTo(b['description']);
        if (descCmp != 0) return descCmp;
        return a['investment_amount'].compareTo(b['investment_amount']);
      });

      setState(() {
        posts = loadedPosts;
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
      final String randomMessage =
          investmentMessages[Random().nextInt(investmentMessages.length)];
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircularProgressIndicator(
                color: Color.fromARGB(255, 16, 76, 18)),
            if (user == null)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(randomMessage,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 6, 105, 16),
                          fontWeight: FontWeight.w500,
                          fontSize: 16),
                      textAlign: TextAlign.center)),
          ]),
        ),
      );
    }
    bool isadmin = false;
    if (_userData?['admin'] == true) isadmin = true;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xffECECEC),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 180, bottom: 60),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                if (projects.isNotEmpty) ...[
                  if (projects.length > 5) ...[
                    _buildSectionTitle("the_most_popular".tr()),
                    const SizedBox(height: 12),
                    _buildImageSlider(
                      projects.take(5).toList(),
                      _currentPopularImageIndex,
                      (index) {
                        setState(() {
                          _currentPopularImageIndex = index;
                        });
                      },
                      5,
                    ),
                    _buildInfoRow(_currentPopularImageIndex, 5),
                    const SizedBox(height: 30),
                    _buildSectionTitle("highest_investment".tr()),
                    const SizedBox(height: 12),
                    _buildImageSlider(
                      projects.take(5).toList(),
                      _currentInvestmentImageIndex,
                      (index) {
                        setState(() {
                          _currentInvestmentImageIndex = index;
                        });
                      },
                      5,
                    ),
                    _buildInfoRow(_currentInvestmentImageIndex, 5),
                    const SizedBox(height: 30),
                    _DisplayItem(),
                  ] else ...[
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
                      projects.length,
                    ),
                    _buildInfoRow(_currentPopularImageIndex, projects.length),
                    const SizedBox(height: 30),
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
                      projects.length,
                    ),
                    _buildInfoRow(
                        _currentInvestmentImageIndex, projects.length),
                    const SizedBox(height: 30),
                    _DisplayItem(),
                  ]
                ],
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

  Widget _DisplayItem() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (ctx, index) {
        final post = posts[index];
        final imageUrl = (post['image_urls'] as List).isNotEmpty
            ? post['image_urls'][0]
            : null;
        final ownerImage = post['owner_image'] ?? 'lib/img/person1.png';
        final dis = post['description'] ?? '';

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      InkWell(
                        onTap: () {
                          Map<String, dynamic> Project;
                          Project = getProjectFromLocalList(
                              post['user_id'], post['projectNumber'])!;
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => Placeholders(Project)));
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15)),
                          child: imageUrl != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Image.network(imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity),
                                )
                              : Image.asset('lib/img/placeholder.png',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(ownerImage,
                                width: 25, height: 25, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                              return Image.asset('lib/img/person1.png',
                                  width: 25, height: 25, fit: BoxFit.cover);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(post['name'] ?? 'No Name',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(dis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                Align(
                  alignment: Alignment(1, .6),
                  child: (post['user_id'] == user?.uid)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StarMenuButton(
                            items: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 103, 90, 89),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0, 2),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Text("Remove",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.2)),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 103, 90, 89),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0, 2),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Text("close",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.2)),
                              ),
                            ],
                            onItemTapped: (index) {
                              if (index == 0) {
                                rejectPost(
                                    context: context,
                                    postNumber: post['postNumber']);
                              } else if (index == 1) {}
                            },
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: StarMenuButton(
                            items: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 103, 90, 89),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0, 2),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Text("Report",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.2)),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 103, 90, 89),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0, 2),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Text("close",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.2)),
                              ),
                            ],
                            onItemTapped: (index) {
                              if (index == 0) {
                                _reportWithReason(post['user_id'],
                                    post['postNumber'], 'Post');
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const SizedBox(width: 23),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                color: Color(0xff012113),
                fontWeight: FontWeight.bold)),
        const Spacer(),
        InkWell(
          child: Text("view_all".tr(),
              style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff54826D),
                  fontWeight: FontWeight.w500)),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => Scaffold(
                    appBar: AppBar(
                        title: Text("All Projects",
                            style: TextStyle(fontSize: 20))),
                    body: Viewitems(projects: projects))));
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildImageSlider(List<Map<String, dynamic>> projectList,
      int currentIndex, Function(int) onChanged, int length) {
    return SizedBox(
      height: 320,
      child: PageView.builder(
        itemCount: length,
        scrollDirection: Axis.horizontal,
        onPageChanged: onChanged,
        itemBuilder: (context, index) {
          if (index >= projectList.length) return SizedBox.shrink();
          final imageUrlList = projectList[index]['image_urls'];
          final imageUrl = (imageUrlList is List && imageUrlList.isNotEmpty)
              ? imageUrlList[0]
              : null;
          final ownerImage =
              projectList[index]['owner_image'] ?? 'lib/img/person1.png';
          final screenWidth = MediaQuery.of(context).size.width;
          final imageSize = screenWidth * 0.9;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              Placeholders(projectList[index])));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: imageUrl != null && imageUrl != ''
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize * 0.8)
                          : Image.asset('lib/img/placeholder.png',
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize * 0.8),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ClipOval(
                      child: Image.network(
                        ownerImage,
                        fit: BoxFit.cover,
                        width: 45,
                        height: 45,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('lib/img/person1.png',
                              fit: BoxFit.cover, width: 45, height: 45);
                        },
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
      return Center(
          child:
              Text("no_projects_found".tr(), style: TextStyle(fontSize: 16)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projects[currentIndex]['name'] ?? 'No Name',
                  style: TextStyle(
                      fontSize: 18,
                      color: Color(0xff000000),
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Text(
                  "Investment: \$${projects[currentIndex]['investment_amount'] ?? 'N/A'}",
                  style: TextStyle(fontSize: 14, color: Color(0xff54826D)),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(totalImages, (index) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? Color(0xff009688)
                      : Color(0xffD9D9D9),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
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
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('lib/img/logo.png', height: 30, width: 30),
                    SizedBox(width: 10),
                    user == null
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                            },
                            child: Text("Login",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          )
                        : Text("Mollni ${user?.displayName ?? ''}",
                            style: TextStyle(
                                fontSize: 20,
                                color: Color(0xff89AE4B),
                                fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.white, size: 30),
                    IconButton(
                        onPressed: () {
                          if (user?.uid == null) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => LoginPage()));
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProfileInformation()));
                          }
                        },
                        icon:
                            Icon(Icons.settings, color: Colors.white, size: 30))
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: CustomSearchBox(
              controller: _searchController,
              onChanged: (value) {
                fetchProjectsAndOwners(null, value);
              },
              hintText: "Search by project name",
              width: double.infinity,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 15),
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: Color(0xff54826D).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                          child: Image.asset('lib/img/img_${index + 1}.png',
                              width: 30, height: 30)),
                    ),
                    onTap: () {
                      String? selectedCategory = categories[index];
                      setState(() {
                        _isLoading = true;
                      });
                      fetchProjectsAndOwners(selectedCategory);
                    },
                  ),
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
        Widget getPageForIndex(int index) {
          if (index == 1) {
            if (user != null && (_userData?['admin'] ?? false)) {
              return Admintapssystem(projects, posts);
            }
            return user != null ? BottomTabs() : const LoginPage();
          } else if (index == 2) {
            return user != null ? MessagesPage() : const LoginPage();
          } else if (index == 3) {
            return user != null ? const Profile() : const LoginPage();
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

  Future<void> rejectPost({
    required BuildContext context,
    required int postNumber,
  }) async {
    final postCollection = FirebaseFirestore.instance.collection('post');

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm removeding'),
        content: const Text('Are you sure you want to remove this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      late final QuerySnapshot querySnapshot;

      if (_userData!['admin']) {
        querySnapshot = await postCollection
            .where('postNumber', isEqualTo: postNumber)
            .limit(1)
            .get();
      } else {
        querySnapshot = await postCollection
            .where('postNumber', isEqualTo: postNumber)
            .where('user_id', isEqualTo: user!.uid)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post not found or no permission')),
        );
        return;
      }

      final docId = querySnapshot.docs.first.id;
      final postDoc = postCollection.doc(docId);

      await postDoc.update({'removed': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post removed successfully!')),
      );
      fetchPostsAndOwners();
    } catch (e) {
      print('Error removeding post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> reportProjectIfNotAlreadyReported(BuildContext context,
      int postNumber, String ownerUserId, String reporttype) async {
    final TextEditingController reasonController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You must be logged in to report."),
          backgroundColor: Colors.red));
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('postNumber', isEqualTo: postNumber)
          .where('user_id', isEqualTo: ownerUserId)
          .get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("error ,not found."), backgroundColor: Colors.red));
        return;
      }
      final projectDoc = querySnapshot.docs.first;
      final reportsSnapshot = await projectDoc.reference
          .collection('reports')
          .where('userUid', isEqualTo: currentUserId)
          .where('reporttype', isEqualTo: reporttype)
          .get();
      if (reportsSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("You have already reported this!"),
            backgroundColor: Colors.orange));
        return;
      }
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: const Text("Report Post"),
                content: TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                        hintText: "Enter reason for reporting")),
                actions: [
                  TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop()),
                  TextButton(
                      child: const Text("Submit"),
                      onPressed: () async {
                        final reason = reasonController.text.trim().isEmpty
                            ? ""
                            : reasonController.text.trim();
                        Navigator.of(context).pop();
                        try {
                          await projectDoc.reference.collection('reports').add({
                            'userUid': currentUserId,
                            'reason': reason,
                            'timeOfReport': Timestamp.now(),
                            'reporttype': reporttype
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Thanks for reporting!"),
                                  backgroundColor:
                                      Color.fromARGB(255, 117, 43, 38)));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red));
                        }
                      })
                ]);
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _reportWithReason(
      String userIdOwner, int numberProject, String reporttype) async {
    try {
      await reportProjectIfNotAlreadyReported(
          context, numberProject, userIdOwner, reporttype);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _saveFcmToken() async {
    if (user == null) return;

    fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'fcmToken': fcmToken,
      });
      print("FCM Token updated in Firestore");
    }
  }
}
