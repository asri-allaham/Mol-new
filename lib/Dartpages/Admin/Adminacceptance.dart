import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Adminacceptance extends StatefulWidget {
  const Adminacceptance({super.key});

  @override
  State<Adminacceptance> createState() => _AdminacceptanceState();
}

bool _isLoading = false;
List<Map<String, dynamic>> projects = [], posts = [];

class _AdminacceptanceState extends State<Adminacceptance> {
  Future<void> fetchPostsAndOwners() async {
    try {
      final query = FirebaseFirestore.instance.collection('post');
      final snapshot = await query.get();

      List<Map<String, dynamic>> loadedPosts = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final postsData = doc.data();
        final userId = postsData['user_id'];
        final adminAccepted = postsData['Adminacceptance'] ?? false;
        if (adminAccepted == true) {
          continue;
        }
        userFutures.add(
          FirebaseFirestore.instance.collection('users').doc(userId).get(),
        );

        loadedPosts.add(postsData);
      }

      final userSnapshots = await Future.wait(userFutures);

      for (int i = 0; i < loadedPosts.length; i++) {
        final userSnapshot = userSnapshots[i];
        final ownerImage = userSnapshot.exists
            ? (userSnapshot.data() as Map<String, dynamic>)['urlImage'] ?? ''
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _DisplayItem() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15)),
                        child: imageUrl != null
                            ? Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Image.asset(
                                'lib/img/placeholder.png',
                                fit: BoxFit.cover,
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
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              ownerImage,
                              width: 25,
                              height: 25,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'lib/img/person1.png',
                                  width: 25,
                                  height: 25,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  dis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('post')
                              .where('user_id', isEqualTo: post['user_id'])
                              .where('postNumber',
                                  isEqualTo: post['postNumber'])
                              .limit(1)
                              .get();
                          if (querySnapshot.docs.isNotEmpty) {
                            final docRef = querySnapshot.docs.first.reference;

                            await docRef.update({'Adminacceptance': true});

                            print(
                                '✅ Adminacceptance set to true for post ${post['postNumber']}');

                            setState(() {
                              post['Adminacceptance'] = true;
                              fetchPostsAndOwners();
                            });
                          } else {
                            print('❌ Post not found.');
                          }
                        } catch (e) {
                          print('❌ Failed to update Adminacceptance: $e');
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 88, 200, 54),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Reject action
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 244, 54, 54),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchProjectsAndOwners() async {
    try {
      final query = FirebaseFirestore.instance.collection('projects');
      final snapshot = await query.get();
      print('-' * 20);
      print(snapshot);
      print('-' * 20);

      List<Map<String, dynamic>> loadedProjects = [];
      List<Future<DocumentSnapshot>> userFutures = [];

      for (var doc in snapshot.docs) {
        final projectData = doc.data();
        final userId = projectData['user_id'];
        final adminAccepted = projectData['Adminacceptance'] ?? false;
        if (adminAccepted == true) continue;

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

  Widget _DisplayProjects() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (ctx, index) {
        final project = projects[index];
        final imageUrl = (project['image_urls'] as List).isNotEmpty
            ? project['image_urls'][0]
            : null;
        final ownerImage = project['owner_image'] ?? 'lib/img/person1.png';
        final dis = project['description'] ?? '';

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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15)),
                        child: imageUrl != null
                            ? Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Image.asset(
                                'lib/img/placeholder.png',
                                fit: BoxFit.cover,
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
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              ownerImage,
                              width: 25,
                              height: 25,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'lib/img/person1.png',
                                  width: 25,
                                  height: 25,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  project['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  dis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('projects')
                              .where('user_id', isEqualTo: project['user_id'])
                              .where('projectNumber',
                                  isEqualTo: project['projectNumber'])
                              .limit(1)
                              .get();
                          if (querySnapshot.docs.isNotEmpty) {
                            final docRef = querySnapshot.docs.first.reference;

                            await docRef.update({'Adminacceptance': true});

                            print(
                                '✅ Adminacceptance set to true for project ${project['projectNumber']}');

                            setState(() {
                              project['Adminacceptance'] = true;
                              fetchProjectsAndOwners();
                            });
                          } else {
                            print('❌ Project not found.');
                          }
                        } catch (e) {
                          print('❌ Failed to update Adminacceptance: $e');
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 88, 200, 54),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Reject logic
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 244, 54, 54),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchPostsAndOwners();
    fetchProjectsAndOwners();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Panel"),
          bottom: TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Projects'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: _DisplayItem()),
            Center(
              child: Center(child: _DisplayProjects()),
            ),
          ],
        ),
      ),
    );
  }
}
