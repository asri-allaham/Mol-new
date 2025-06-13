import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Adminacceptance extends StatefulWidget {
  const Adminacceptance({super.key});

  @override
  State<Adminacceptance> createState() => _AdminacceptanceState();
}

class _AdminacceptanceState extends State<Adminacceptance>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> projects = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([fetchPostsAndOwners(), fetchProjectsAndOwners()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchPostsAndOwners() async {
    final query = FirebaseFirestore.instance.collection('post');
    final snapshot = await query.get();

    List<Map<String, dynamic>> loadedPosts = [];
    List<Future<DocumentSnapshot>> userFutures = [];

    for (var doc in snapshot.docs) {
      final postData = doc.data();
      final userId = postData['user_id'];
      final adminAccepted = postData['Adminacceptance'] ?? false;
      if (adminAccepted) continue;

      userFutures.add(
        FirebaseFirestore.instance.collection('users').doc(userId).get(),
      );

      loadedPosts.add(postData);
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
    });
  }

  Future<void> fetchProjectsAndOwners() async {
    final query = FirebaseFirestore.instance.collection('projects');
    final snapshot = await query.get();

    List<Map<String, dynamic>> loadedProjects = [];
    List<Future<DocumentSnapshot>> userFutures = [];

    for (var doc in snapshot.docs) {
      final projectData = doc.data();
      final userId = projectData['user_id'];
      final adminAccepted = projectData['Adminacceptance'] ?? false;
      if (adminAccepted != true) continue;

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
    });
  }

  Widget _buildGrid(List<Map<String, dynamic>> items, String type) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 0.72,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, index) {
        final item = items[index];
        final imageUrl = (item['image_urls'] as List).isNotEmpty
            ? item['image_urls'][0]
            : null;
        final ownerImage = item['owner_image'] ?? 'lib/img/person1.png';
        final dis = item['description'] ?? '';

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Image.asset('lib/img/placeholder.png',
                                fit: BoxFit.cover),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              ownerImage,
                              width: 25,
                              height: 25,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                  'lib/img/person1.png',
                                  width: 25,
                                  height: 25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['name'] ?? 'No Name',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  dis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final collection =
                            FirebaseFirestore.instance.collection(type);
                        final querySnapshot = await collection
                            .where('user_id', isEqualTo: item['user_id'])
                            .where('postNumber', isEqualTo: item['postNumber'])
                            .limit(1)
                            .get();
                        if (querySnapshot.docs.isNotEmpty) {
                          final docRef = querySnapshot.docs.first.reference;
                          await docRef.update({'Adminacceptance': true});
                          fetchAllData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 88, 200, 54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 244, 54, 54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Acceptance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Projects'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(posts, 'post'),
                _buildGrid(projects, 'projects'),
              ],
            ),
    );
  }
}
